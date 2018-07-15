#!/usr/bin/env bash
submodule_get(){
	if [ ! -f .gitmodules ]; then
		return 1
	fi
	cat .gitmodules|grep "path = "|sed 's/^.*=\s\+//'
}
get_branch_name(){
	git rev-parse --abbrev-ref HEAD
}
lasttag(){
	prefix=$1
	git fetch --all 1>/dev/null
	status=$?
	[ $status -ne 0 ] && return $status
	st_curdate=$(date +%Y%m%d)
	tag_prefix="${prefix}_${st_curdate}"
	last_tag=$(git tag|grep "${tag_prefix}[[:digit:]]\+"|tail -1)
	echo $last_tag
}
nexttag(){
	prefix=$1;
	if [ "x${prefix}" = "x" ]; then
		echo -e "tag_prefix is required\n\ttag_prefix example qa, prod">&2
		return 4
	fi
	last_tag=$(lasttag $prefix)
	status=$?
	[ 0 -ne $status ] && return $status
	st_curdate=$(date +%Y%m%d)
	if [ "x${last_tag}" = "x" ]; then
		next_index="${st_curdate}00";
	else
		current_index=$(echo $last_tag|sed "s/.*\?\(${st_curdate}[[:digit:]]\+\)_.*$/\1/g")
		next_index=$(($current_index + 1))
	fi
	echo "${prefix}_${next_index}"
}
settag(){
	prefix=$1
	message=${@//$prefix/}
	next_tag=$(nexttag $prefix)
	status=$?
	[ 0 -ne $status ] && return $status
	cur_branch=$(get_branch_name)
	status=$?
	[ 0 -ne $status ] && return $status
	if [ "prod" = "$prefix" ]; then
		if [ "master" != "${cur_branch}" ]; then
			echo "forbidden to set prod tag on non master">&2
			return 8
		fi
		if [ "x$message" = "x" ]; then
			echo "message is required for prod tag">&2
			return 5
		fi
	fi
	if [ "qa" = "$prefix" ] && [ "master" = "${cur_branch}" ]; then
		echo "forbidden to set qa tag on master">&2
		return 7
	fi
	next_tag="${next_tag}_${cur_branch}"
	[ "x$message" = "x" ] || next_tag="${next_tag}_${message//[^a-zA-Z0-9_]/-}"
	git tag "${next_tag}" && git push --tags
}
settag_qa(){
	settag "qa" "$@"
}
settag_prod(){
	settag "prod" "$@"
}
gitpl(){
	for submodule_folder in $(submodule_get); do
		if [ ! -d "$submodule_folder" ]; then
			continue;
		fi;
		(cd "$submodule_folder";gitpl "$@")
		status=$?
		[ 0 -ne $status ] && return $status
	done
	git pull "$@"
}
gitplo(){
	cur_branch=$(get_branch_name)
	gitpl origin "${cur_branch}"
}
gitps(){
	for submodule_folder in $(submodule_get); do
		if [ ! -d "$submodule_folder" ]; then
			continue;
		fi;
		(cd "$submodule_folder";gitps "$@")
		status=$?
		[ 0 -ne $status ] && return $status
	done
	git push "$@"
}
gitpso(){
	cur_branch=$(get_branch_name)
	gitps origin "${cur_branch}"
}
gitco(){
	for submodule_folder in $(submodule_get); do
		if [ ! -d "$submodule_folder" ]; then
			continue;
		fi;
		(cd "$submodule_folder";gitco "$@")
		status=$?
		[ 0 -ne $status ] && return $status
	done
	git checkout "$@"
}
newbranch(){
	branch_name=$@
	gitco -b "$branch_name" && gitps --set-upstream origin "$branch_name"
}
gitci(){
	for submodule_folder in $(submodule_get); do
		if [ ! -d "$submodule_folder" ]; then
			continue;
		fi;
		(cd "$submodule_folder";gitci "$@")
		status=$?
		#git commit return status 1 - Nothing to commit, not error
		[ 0 -ne $status ] && [ 1 -ne $status ] && return $status
	done
	git commit "$@"
}
gitciam(){
	message=$@
	gitci -am "${message}"
	status=$?
	#git commit return status 1 - Nothing to commit, not error
	[ 0 -ne $status ] && [ 1 -ne $status ] && return $status
	cur_branch=$(get_branch_name)
	status=$?
	[ 0 -ne $status ] && return $status
	gitps origin "$cur_branch"
}

mergewith(){
	cur_branch=$(git rev-parse --abbrev-ref HEAD)
	branch_to_merge=$@
	gitpl origin "$cur_branch"
	gitco "$branch_to_merge" && gitpl
	status=$?
	gitco "$cur_branch"
	if [ 0 -ne $status ]; then
		return $status
	fi
	mergefn(){
		status=0
		for submodule_folder in $(submodule_get); do
			if [ ! -d "$submodule_folder" ]; then
				continue;
			fi;
			(cd "$submodule_folder";mergefn "$@") || status=$?
		done
		(git merge --no-commit -Xignore-all-space "$@") || status=$?
		return $status
	}
	mergefn "${branch_to_merge}"
	status=$?
	if [ 0 -ne $status ]; then
		git status
	else
		gitciam "Merge with ${branch_to_merge}"
	fi
	return $status
}

cdp(){
	project_root="/srv/"
	project=$@
	folder="${project_root}${project}"
	if [ -d $folder ]; then
		cd $folder;
		return 0;
	fi
	folder=""
	case $project in
		"store")
			folder="${project_root}store.icq.com"
			;;

		"files")
			folder="${project_root}files.icq"
			;;
		"icq")
			folder="${project_root}www.icq.com/htdocs/private"
			;;
		"search")
			folder="${project_root}search.icq.com"
			;;
		"webcms")
			folder="${project_root}webcms.icq.com/htdocs/private"
			;;
		"voip")
			folder="${project_root}voip.icq.com/private"
			;;
		"siteim")
			folder="${project_root}www.icq.com/htdocs/siteim"
			;;
	esac
	if [ "x${folder}" == "x" ]; then
		echo "project ${project} not found">&2
		return 1
	fi
	cd $folder;
}