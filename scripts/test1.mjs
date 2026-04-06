#!/usr/bin/env zx

const branchName = "feature-ui-update";

await $`git checkout -b ${branchName}`;

// check if the branch exists in remote
// if it does
//   create a new worktree
//   checkout the branch
