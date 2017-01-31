# == Class: windows_services
#
# This module allow you to manage credential of a windows_services
#
# === Parameters
#
#  Can be found on read me
#
# === Examples
#
#  windows_services::credentials{'puppet':
#    username    = "DOMAIN\User",
#    password    = "P@ssw0rd",
#    servicename = "puppet",
#  }
# === Authors
#
# Jerome RIVIERE (www.jerome-riviere.re)
#
# === Copyright
#
# Copyright 2014 Jerome RIVIERE, unless otherwise noted.
#
define windows_services::credentials(
  $username    = '',
  $password    = '',
  $servicename = '',
  $delayed     = false,
  $carbondll   = "C:\\Carbon.dll",
){
  if(empty($username)){
    fail('Username is mandatory')
  }
  if(empty($password)){
    fail('Password is mandatory')
  }
  if(empty($servicename)){
    fail('servicename is mandatory')
  }
  validate_bool($delayed)
  require windows_services::carbon
  exec{"Change credentials - $servicename":
    command  => template("${module_name}/change_credentials.ps1.erb"),
    provider => "powershell",
    timeout  => 300,
    onlyif   => template("${module_name}/query_credentials.ps1.erb"),
  }

  if($delayed){
    $value = '1' 
  }else{
    $value = '0'
  }

  exec{"Set Start_Delayed - $servicename":
    command  => "New-ItemProperty -Path \"HKLM:\\System\\CurrentControlSet\\Services\\${servicename}\" -Name 'DelayedAutoStart' -Value '${value}' -PropertyType 'DWORD' -Force;",
    provider => "powershell",
    timeout  => 300,
    onlyif   => "if((test-path \"HKLM:\\System\\CurrentControlSet\\Services\\${servicename}\\\") -eq \$true){if((Get-ItemProperty -Path \"HKLM:\\System\\CurrentControlSet\\Services\\${servicename}\" -ErrorAction SilentlyContinue).DelayedAutoStart -eq '${value}'){exit 1;}else{exit 0;}}else{exit 1;}",
  }
  File["${carbondll}"] -> Exec["Change credentials - $servicename"] -> Exec["Set Start_Delayed - $servicename"]
}