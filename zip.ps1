Remove-Item '.\DSC\iis.zip'
Publish-AzVMDscConfiguration .\DSC\iis.ps1 -OutputArchivePath '.\DSC\iis.zip'

git add .
git commit -m "zip"
git push