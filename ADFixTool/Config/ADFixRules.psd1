@{
    # ---------------------------------------------------------------------
    # Shared limits/patterns used by more than one rule below. Change these
    # in one place rather than hunting through rule definitions.
    # ---------------------------------------------------------------------
    Limits = @{
        UPNMaxLength         = 113   # Entra ID hard limit (64 local-part + 1 '@' + 48 domain, +48 more via UPN suffix rules; 113 is the enforced total)
        MailMaxLength         = 256
        DisplayNameMaxLength = 256
        NameMaxLength         = 64
    }

    Patterns = @{
        # Characters Entra ID accepts in the local part of a UserPrincipalName.
        ValidUPNLocalPart      = '^[a-zA-Z0-9!#$%&''*+/=?^_`{|}~.-]+$'
        UPNLeadingTrailingDot  = '(^\.)|(\.$)|(\.\.)'
        ValidEmailFormat       = '^[^@\s]+@[^@\s]+\.[^@\s]+$'
        ProxyAddressPrefix     = '^(SMTP|smtp|X500|x500|SIP|sip|SPO|smsms):'
        LeadingTrailingSpace   = '^\s|\s$'
    }

    # ---------------------------------------------------------------------
    # Rule catalog. Each entry is one check run against every in-scope AD
    # user. To add a rule: write a Test-ADFix* function under Private/ that
    # takes ($User, $Context, $Rule) and returns $true when the user VIOLATES
    # the rule, then add an entry here. To disable a rule: delete/comment its
    # entry, no code changes needed.
    #
    #   Id          - unique short name, shows up in reports
    #   Attribute   - AD attribute the rule inspects (informational + used by Test-ADFixAttributeLength/BlankAttribute)
    #   Severity    - 'Error' (will not sync / will sync wrong) or 'Warning' (cosmetic / best practice)
    #   Description - human-readable text shown in the report
    #   Check       - name of the Private function implementing the rule
    #   Param       - optional extra value passed to the check function (e.g. a length limit)
    # ---------------------------------------------------------------------
    Rules = @(
        @{ Id = 'UPN-Blank';               Attribute = 'UserPrincipalName'; Severity = 'Error';   Description = 'UserPrincipalName is blank.';                                    Check = 'Test-ADFixBlankAttribute' }
        @{ Id = 'UPN-InvalidCharacter';    Attribute = 'UserPrincipalName'; Severity = 'Error';   Description = 'UserPrincipalName contains a character not supported by Entra ID.'; Check = 'Test-ADFixUPNCharacter' }
        @{ Id = 'UPN-TooLong';             Attribute = 'UserPrincipalName'; Severity = 'Error';   Description = 'UserPrincipalName exceeds the Entra ID length limit.';           Check = 'Test-ADFixAttributeLength'; Param = 113 }
        @{ Id = 'UPN-Duplicate';           Attribute = 'UserPrincipalName'; Severity = 'Error';   Description = 'UserPrincipalName is not unique across the checked users.';       Check = 'Test-ADFixDuplicateValue' }

        @{ Id = 'Mail-InvalidFormat';      Attribute = 'mail';              Severity = 'Warning'; Description = 'mail attribute is not a valid SMTP address.';                    Check = 'Test-ADFixMailFormat' }
        @{ Id = 'Mail-TooLong';            Attribute = 'mail';              Severity = 'Warning'; Description = 'mail attribute exceeds the recommended length limit.';          Check = 'Test-ADFixAttributeLength'; Param = 256 }
        @{ Id = 'Mail-Duplicate';          Attribute = 'mail';              Severity = 'Error';   Description = 'mail attribute is not unique across the checked users.';         Check = 'Test-ADFixDuplicateValue' }

        @{ Id = 'ProxyAddress-BadFormat';       Attribute = 'proxyAddresses'; Severity = 'Error';   Description = 'proxyAddresses entry does not start with a valid SMTP/X500/SIP prefix.'; Check = 'Test-ADFixProxyAddressFormat' }
        @{ Id = 'ProxyAddress-NoPrimarySMTP';   Attribute = 'proxyAddresses'; Severity = 'Error';   Description = 'No primary (uppercase SMTP:) address present in proxyAddresses.';        Check = 'Test-ADFixProxyPrimaryMissing' }
        @{ Id = 'ProxyAddress-MultiplePrimary'; Attribute = 'proxyAddresses'; Severity = 'Error';   Description = 'More than one primary SMTP: address present in proxyAddresses.';         Check = 'Test-ADFixProxyMultiplePrimary' }
        @{ Id = 'ProxyAddress-Duplicate';       Attribute = 'proxyAddresses'; Severity = 'Error';   Description = 'A proxyAddresses value is duplicated on another user.';                  Check = 'Test-ADFixDuplicateProxyAddress' }

        @{ Id = 'DisplayName-TooLong';     Attribute = 'DisplayName'; Severity = 'Warning'; Description = 'DisplayName exceeds the recommended length limit.';        Check = 'Test-ADFixAttributeLength'; Param = 256 }
        @{ Id = 'GivenName-BadCharacter';  Attribute = 'GivenName';   Severity = 'Warning'; Description = 'GivenName has a leading/trailing space or unsupported character.'; Check = 'Test-ADFixNameCharacter' }
        @{ Id = 'Surname-BadCharacter';    Attribute = 'Surname';     Severity = 'Warning'; Description = 'Surname has a leading/trailing space or unsupported character.';   Check = 'Test-ADFixNameCharacter' }
    )
}
