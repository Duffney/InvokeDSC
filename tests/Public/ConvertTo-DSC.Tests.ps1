. "$PSScriptRoot\..\..\InvokeDSC\Public\ConvertTo-DSC.ps1"

Describe "Function Loaded" {

    it "command exists" {
        (Get-Command -Name ConvertTo-DSC) | should not beNullorEmpty
    }

    BeforeAll {
        $newFileJson = @"
{
   "DSCResourcesToExecute":{
       "NewFile":{
          "dscResourceName":"File",
          "destinationPath":"c:\\archtype\\file.txt",
          "type":"File",
          "contents":"Test",
          "attributes":["hidden","archive"],
          "ensure":"Present",
          "force":true
          }
      }
}
"@

    $xWebSiteJson = @"
    {
        "Modules":{
                 "xWebAdministration":null
        },
        "DSCResourcesToExecute":{
          "archtype": {
              "dscResourceName":"File",
              "DestinationPath":"c:\\archtype",
              "Type":"Directory",
              "ensure":"Present"
           },
           "archtypeSite":{
              "dscResourceName":"xWebsite",
              "name":"archtype",
              "State":"Started",
              "physicalPath":"c:\\archtype",
              "ensure":"Present",
              "bindingInfo":[
                 {
                    "CimType":"MSFT_xWebBindingInformation",
                    "Properties":{
                          "protocol":"http",
                          "port":8081,
                          "ipaddress":"127.0.0.1"
                       }
                 },
                 {
                    "CimType":"MSFT_xWebBindingInformation",
                    "Properties":{
                          "protocol":"http",
                          "port":8080,
                          "ipaddress":"127.0.0.1"
                       }
                 }
              ],
               "AuthenticationInfo":[
                     {
                         "CimType":"MSFT_xWebAuthenticationInformation",
                         "Properties":{
                             "Anonymous":true,
                             "Basic":true
                         }
                     }
                ]
           }
        }
     }
"@

    $xWebApplication = @"
    {
        "Modules":{
                 "xWebAdministration":null
        },
        "DSCResourcesToExecute":{
           "archtype":{
              "dscResourceName":"File",
              "DestinationPath":"c:\\archtype\\DevOps",
              "Type":"Directory",
              "ensure":"Present"
           },
           "DevOpsApp":{
               "dscResourceName":"xWebApplication",
               "name":"DevOps",
               "PhysicalPath":"C:\\archtype\\DevOps",
               "WebAppPool":"DefaultAppPool",
               "WebSite":"Default Web Site",
               "PreloadEnabled":true,
               "EnabledProtocols":["http"],
               "Ensure":"Present",
               "AuthenticationInfo":[
                     {
                         "CimType":"MSFT_xWebApplicationAuthenticationInformation",
                         "Properties":{
                             "Anonymous":true,
                             "Basic":true
                         }
                     }
                ]
           }
        }
     }
"@

     $moduleVersion = @"
     {
        "Modules":{
                "xPSDesiredStateConfiguration":"6.4.0.0"
    },
       "DSCResourcesToExecute":{
            "DevOpsGroup":{
                "dscResourceName":"xGroup",
                "GroupName":"DevOps",
                "ensure":"Present"
            }
       }
    }
"@

    New-Item -Path 'testdrive:\newfile.json' -Value $newFileJson -ItemType File
    New-Item -Path 'testdrive:\xWebSite.json' -Value $xWebSiteJson -ItemType File
    New-Item -Path 'testdrive:\xWebApplication.json' -Value $xWebApplication -ItemType File
    New-Item -Path 'testdrive:\moduleVersion.json' -Value $moduleVersion -ItemType File
}

    Context "Parameter Tests" {

        $result = ConvertTo-DSC -InputObject (Get-Content -Path "testdrive:\xWebSite.json")

        It "InputObject results should not BeNullorEmpty" {
            $result | Should not beNullorEmpty
        }

        $result = ConvertTo-DSC -Path "testdrive:\xWebSite.json"

        It "Path results should not BeNullorEmpty" {
            $result | should not be beNullorEmpty
        }
    }

    Context "File Resource Test" {

        $result = ConvertTo-DSC -Path "testdrive:\newfile.json"

        it "result should not be null" {
            $result | should not beNullorEmpty
        }

        it "resourceName should be NewFile" {
            $result.resourceName | should be 'NewFile'
        }

        it "dscResourceName should be File" {
            $result.dscResourceName | should be 'File'
        }

        it "ModuleName should be PSDesiredStateConfiguration" {
            $result.ModuleName | should be 'PSDesiredStateConfiguration'
        }

        it "destinationPath should be c:\archtype\Service\file.txt" {
            $result.Property.destinationPath | should be 'c:\archtype\file.txt'
        }

        it "force should be true" {
            $result.Property.force | should be $true
        }

        it "force should be bool" {
            $result.Property.force | should BeofType bool
        }

        it "attributes should be array" {
            $result.Property.attributes -is [System.Array] | should be $true
        }

        it "attributes should match hidden,archive" {
            $result.Property.attributes | should match 'Hidden|Archive'
        }
    }

    Context "xWebApplication Test" {

        $result = ConvertTo-DSC -Path 'testdrive:\xWebApplication.json'

        it "AuthenticationInfo should be type of ciminstnace" {
            $result[1].Property.AuthenticationInfo.GetType().Name | should be 'CimInstance'
        }

        it "Anonymous should BeofType bool" {
            $result[1].Property.AuthenticationInfo.Anonymous | should BeofType bool
        }
    }

    Context "xWebSite" {
        $result = ConvertTo-DSC -Path 'testdrive:\xWebSite.json'

        it "bindinginfo should be CimInstance[]" {
            $result[1].Property.bindinginfo.GetType().Name | should be 'CimInstance[]'
        }

        it "bindinginfo port should be UInt32" {
            $result.Property.bindinginfo[0].port | should BeofType 'Int32'
        }

        it "bindinginfo protocol should match http|https|net.tcp" {
            $result.Property.bindinginfo[0].protocol | should match 'https?|net.tcp'
        }

        it "bindinginfo protocol should be String" {
            $result.Property.bindinginfo[0].protocol | should BeofType 'string'
        }
    }
}

Describe 'Module Version Tests' {

    BeforeAll {

     $moduleVersion = @"
     {
        "Modules":{
            "xPSDesiredStateConfiguration":"6.4.0.0"
        },
       "DSCResourcesToExecute":{
            "DevOpsGroup":{
                "dscResourceName":"xGroup",
                "GroupName":"DevOps",
                "ensure":"Present"
            }
       }
    }

"@
$xWebSiteJson = @"
{
    "Modules":{
        "xWebAdministration":null
    },
    "DSCResourcesToExecute":{
      "archtype": {
          "dscResourceName":"File",
          "DestinationPath":"c:\\archtype",
          "Type":"Directory",
          "ensure":"Present"
       },
       "archtypeSite":{
          "dscResourceName":"xWebsite",
          "name":"archtype",
          "State":"Started",
          "physicalPath":"c:\\archtype",
          "ensure":"Present",
          "bindingInfo":[
             {
                "CimType":"MSFT_xWebBindingInformation",
                "Properties":{
                      "protocol":"http",
                      "port":8081,
                      "ipaddress":"127.0.0.1"
                   }
             },
             {
                "CimType":"MSFT_xWebBindingInformation",
                "Properties":{
                      "protocol":"http",
                      "port":8080,
                      "ipaddress":"127.0.0.1"
                   }
             }
          ],
           "AuthenticationInfo":[
                 {
                     "CimType":"MSFT_xWebAuthenticationInformation",
                     "Properties":{
                         "Anonymous":true,
                         "Basic":true
                     }
                 }
            ]
       }
    }
 }
"@
        New-Item -Path 'testdrive:\moduleVersion.json' -Value $moduleVersion -ItemType File
        New-Item -Path 'testdrive:\xWebSite.json' -Value $xWebSiteJson -ItemType File
    }
    Context "Module Versions" {
        $result = ConvertTo-DSC -Path 'testdrive:\xWebSite.json'
        $moduleVersionResult = ConvertTo-Dsc -Path 'testdrive:\moduleVersion.json'
        it 'ModuleVersion should be $null' {
            $result[1].Property.ModuleVersion | should be $null
        }

        it 'ModuleVersion should be 6.4.0.0' {
            $moduleVersionResult.ModuleVersion | should be '6.4.0.0'
        }
    }
}

Describe 'Converting PSCredential Object Tests' {
    BeforeAll {
        $credConfig = @"
{
    "Modules":{
        "xSQLServer":null
    },
    "DSCResourcesToExecute":{
        "CreateLogin":{
        "dscResourceName":"xSQLServerLogin",
        "Name":"SQLLoginUserName",
        "SQLServer":"SQLServer01",
        "SQLInstanceName":"MSSQLSERVER",
        "LoginCredential":"UserName\\Password"
        }
    }
}
"@
    }

    $result = ConvertTo-Dsc -InputObject $credConfig

    it 'Property.LoginCredential should be type PSCredential' {
        ($result.Property.LoginCredential).GetType().Name | should be 'PSCredential'
    }
    it 'Property.LoginCredential should be type PSCredential' {
        ($result.Property.LoginCredential).UserName | should be 'UserName'
    }
}

Describe 'ConvertTo-DSC Invalid Configurations'  {
    Context 'Invalid dscResourceName' {
        $config = @"
        {
            "Modules":{
                "xSQLServer":null
            },
            "DSCResourcesToExecute":{
                "CreateLogin":{
                "Name":"SQLLoginUserName",
                "SQLServer":"SQLServer01",
                "SQLInstanceName":"MSSQLSERVER",
                "LoginCredential":"UserName\\Password"
                }
            }
        }
"@

        It 'Should_Throw_dscResourceNameisNull' {
            {ConvertTo-Dsc -InputObject $config} | Should -Throw
        }
    }
}

Describe 'Dynamic Array to String' {
    Context 'xScript String Array to String' {
        $config = @"
{
    "Modules":{
        "xSQLServer":null
    },
    "DSCResourcesToExecute":{
        "StringArray":{
            "dscResourceName":"xScript",
            "SetScript":[
                "itemOne",
                "itemTwo",
                "itemThree"
            ],
            "TestScript":"`$false",
            "GetScript":"{ @{ Result = () } } "
        }
    }
}
"@
        It 'Should_BeOfType_String' {
            $resource = ConvertTo-Dsc -InputObject $config
            $resource.Property.SetScript | Should -BeOfType 'string'
        }
    }
}
