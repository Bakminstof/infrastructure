@{
    Severity     = @('Error', 'Warning')
    IncludeRules = @(
        'PSAvoidUsingWriteHost',
        'PSAvoidUsingConvertToSecureStringWithPlainText',
        'PSAvoidUsingCmdletAliases',
        'PSAvoidUsingPositionalParameters',
        'PSUseConsistentIndentation',
        'PSUseConsistentWhitespace',
        'PSUseCorrectCasing',
        'PSUseBOMForUnicodeEncodedFile'
    )
}
