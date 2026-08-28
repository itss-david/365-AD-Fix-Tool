function Convert-ADFixImmutableId {
    <#
        .SYNOPSIS
            Computes the Base64 ImmutableID Entra Connect would generate for an AD
            user, so it can be matched against a cloud user's OnPremisesImmutableId.

        .PARAMETER SourceAnchor
            The raw source-anchor value from AD: ObjectGUID (default sync anchor) or,
            when the tenant uses ms-DS-ConsistencyGuid instead, that attribute's bytes.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [byte[]]$SourceAnchor
    )

    return [System.Convert]::ToBase64String($SourceAnchor)
}
