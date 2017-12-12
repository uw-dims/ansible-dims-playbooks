#!/usr/bin/env bats
#
# vim: set ts=4 sw=4 tw=0 et :

@test "[S][EV] DO_API_VERSION (dopy) is defined in environment" {
    [ ! -z "$DO_API_VERSION" ]
}

@test "[S][EV] DO_API_TOKEN (dopy) is defined in environment" {
    [ ! -z "$DO_API_TOKEN" ]
}

@test "[S][EV] DO_PAT (terraform) is defined in environment" {
    [ ! -z "$DO_PAT" ]
}

@test "[S][EV] DO_API_TOKEN authentication succeeds" {
    ! bash -c "make images | grep 'Unable to authenticate you'"
}

@test "[S][EV] TF_VAR_public_key (terraform .tf) is defined in environment" {
    [ ! -z "$TF_VAR_public_key" ]
}

@test "[S][EV] File pointed to by TF_VAR_public_key exists and is readable" {
    [ -r "$TF_VAR_public_key" ]
}

@test "[S][EV] TF_VAR_private_key (terraform .tf) is defined in environment" {
    [ ! -z "$TF_VAR_private_key" ]
}

@test "[S][EV] File pointed to by TF_VAR_private_key exists and is readable" {
    [ -r "$TF_VAR_private_key" ]
}

@test "[S][EV] TF_VAR_ssh_fingerprint (terraform .tf) is defined in environment" {
    [ ! -z "$TF_VAR_ssh_fingerprint" ]
}

@test "[S][EV] DO_API_TOKEN authentication succeeds" {
    ! bash -c "make images | grep 'Unable to authenticate you'"
}

@test "[S][EV] terraform is found in \$PATH" {
    which terraform
}
