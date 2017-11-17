# SVN to Git Migration

This repository consists of scripts used during the migration of many Subversion repositories to Git.

This branch is based on [this wonderful guide](https://www.atlassian.com/git/tutorials/migrating-overview) from Atlassian. The scripts here aim to automate the steps in this guide for use across a large number of repositories.

This branch represents a mostly failed attempt. A number of issues led to this being a dead end including:
 * Poor performance of git-svn,
 * Repository structure limitations,
 * Segmentation faults encontered in git-svn.

In addition to these limitations, the ability to synchronize changes between git and SVN repositories, which is the main advantage of this method, was deemed unnecessary.

The master branch will show a (hopefully) successful approach.
