function Build-ADFixDuplicateIndex {
    <#
        .SYNOPSIS
            Pre-indexes attribute values across the whole user set once, so per-user
            duplicate checks are O(1) lookups instead of re-scanning every user.

        .OUTPUTS
            Hashtable with:
              SingleValue.<AttributeName>  -> @{ <lowercased value> = <count> }
              ProxyAddress                 -> @{ <lowercased 'type:address'> = <count> }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$Users,

        [string[]]$SingleValueAttributes = @('UserPrincipalName', 'mail')
    )

    $index = @{
        SingleValue  = @{}
        ProxyAddress = @{}
    }

    foreach ($attribute in $SingleValueAttributes) {
        $index.SingleValue[$attribute] = @{}
    }

    foreach ($user in $Users) {
        foreach ($attribute in $SingleValueAttributes) {
            $value = $user.$attribute
            if (-not [string]::IsNullOrWhiteSpace($value)) {
                $key = $value.Trim().ToLowerInvariant()
                $bucket = $index.SingleValue[$attribute]
                $bucket[$key] = [int]($bucket[$key]) + 1
            }
        }

        foreach ($proxy in @($user.proxyAddresses)) {
            if ([string]::IsNullOrWhiteSpace($proxy)) { continue }
            $key = $proxy.Trim().ToLowerInvariant()
            $index.ProxyAddress[$key] = [int]($index.ProxyAddress[$key]) + 1
        }
    }

    return $index
}
