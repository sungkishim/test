echo "this is test.sh"

# get latest tag
t=$(git describe --tags `git rev-list --tags --max-count=1`)
echo "Latest tag : $t"

f=$(pwd)
echo "pwd : f"

# get current commit hash for tag
commit=$(git rev-parse HEAD)

# if there are none, start tags at 0.0.0
if [ -z "$t" ]
then
    log=$(git log --pretty=oneline)
    t=0.0.0
else
    log=$(git log $t..HEAD --pretty=oneline)
fi

echo "log : $log"

# get commit logs and determine home to bump the version
# supports #major, #minor, #patch (anything else will be 'patch')
case "$log" in
    *#major* ) new=$(./.github/scripts/semver bump major $t);;
    *#minor* ) new=$(./.github/scripts/semver bump minor $t);;
    * ) new=$(./.github/scripts/semver bump patch $t);;
esac

echo "New tag : $new"

# get repo name from git
remote=$(git config --get remote.origin.url)
repo=$(basename $remote .git)

echo "remote : $remote"
echo "repo : $repo"

# POST a new ref to repo via Github API
curl -s -X POST https://api.github.com/repos/sungkishim/$repo/git/refs \
-H "Authorization: token $GITHUB_TOKEN" \
-d @- << EOF
{
  "ref": "refs/tags/$new",
  "sha": "$commit"
}
EOF

