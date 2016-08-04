:: TODO: This is very outdated

if not exist "C:\Windows\Temp\puppet.msi" (
  powershell -Command "(New-Object System.Net.WebClient).DownloadFile('http://pm.puppetlabs.com/puppet-enterprise/%2/puppet-enterprise-%2.msi', 'C:\Windows\Temp\puppet.msi')" <NUL
)

set /a certname=%RANDOM% * (100000000 - 99999999)

:: http://docs.puppetlabs.com/pe/latest/install_windows.html
msiexec /qn /i C:\Windows\Temp\puppet.msi PUPPET_MASTER_SERVER="%1" PUPPET_AGENT_CERTNAME="vagrant-w-%certname%.vagrant.vm" /log C:\Windows\Temp\puppet.log

:: <nul set /p ".=;C:\Program Files (x86)\Puppet Labs\Puppet Enterprise\bin" >> C:\Windows\Temp\PATH
:: set /p PATH=<C:\Windows\Temp\PATH
:: setx PATH "%PATH%" /m

"c:\Program Files (x86)\Puppet Labs\Puppet Enterprise\bin\puppet.bat" config set basemodulepath c:\vagrant\%4;c:\vagrant\%3\modules;c:\vagrant\%3\site --section main

copy c:\vagrant\vagrant\hiera_windows.yaml c:\programdata\puppetlabs\puppet\etc\hiera.yaml
