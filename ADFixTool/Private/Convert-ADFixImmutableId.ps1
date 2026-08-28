function Convert-ADFixImmutableId {
    <#
        .SYNOPSIS
            Computes the Base64 ImmutableID Entra Connect would generate for an AD
            user, so it can be matched against a cloud user's OnPremisesImmutableId.

        .PARAMETER SourceAnchor
            The raw source-anchor value from AD. Get-ADUser's ObjectGUID (the default
            sync anchor) comes back as a [System.Guid]; ms-DS-ConsistencyGuid (used
            when a tenant is configured for that anchor instead) comes back as a
            [byte[]]. Both are accepted here.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$SourceAnchor
    )

    if ($SourceAnchor -is [System.Guid]) {
        $bytes = $SourceAnchor.ToByteArray()
    }
    elseif ($SourceAnchor -is [byte[]]) {
        $bytes = $SourceAnchor
    }
    else {
        throw "Unsupported source anchor type '$($SourceAnchor.GetType().FullName)'. Expected [System.Guid] or [byte[]]."
    }

    return [System.Convert]::ToBase64String($bytes)
}
