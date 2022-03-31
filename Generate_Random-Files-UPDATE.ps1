## https://www.catapultsystems.com/blogs/powershell-create-randomfiles-ps1/
## Create-RandomFiles.ps1 -TotalSize 1GB -NumberOfFiles 123 -Path $env:Temp -FilesTypes 'Office' -NamePrefix '~'
## Create-RandomFiles -TotalSize 200KB -NumberOfFiles 12 -Path C:\Users\Administrator\Desktop -filesType 'Office' -NamePrefix '~'


Function Create-RandomFiles{
[cmdletbinding()]
param(
    [Parameter(mandatory=$true)]$NumberOfFiles,
    [Parameter(mandatory=$true)]$path,
    [Parameter(mandatory=$true)]$TotalSize,
    [Parameter(mandatory=$false)][validateSet("Multimedia","Image","Office","Office2","Junk","Archive","Script","all","")][String]$FilesType=$all,
    [Parameter(mandatory=$false)]$NamePrefix=""
)
 
begin{
    $StartTime = (get-date)
    $TimeSpan = New-TimeSpan -Start $StartTime -end $(Get-Date) #New-TimeSpan -seconds $(($(Get-Date)-$StartTime).TotalSeconds)
    $Progress=@{Activity = "Create Random Files..."; Status="Initializing..."}
    Write-verbose "Generating files"
    $AllCreatedFilles = @()
 
    function Create-FileName {
        [CmdletBinding(SupportsShouldProcess=$true)]
        param(
            [Parameter(mandatory=$false)][validateSet("Multimedia","Image","Office","Office2","Junk","Archive","Script","all","")][String]$FilesType=$all,
		    [Parameter(mandatory=$false)]$NamePrefix=""
		)
        begin {
			$AllExtensions = @()
			$MultimediaExtensions = ".avi",".midi",".mov",".mp3",".mp4",".mpeg",".mpeg2",".mpeg3",".mpg",".ogg",".ram",".rm",".wma",".wmv"
			$ImageExtensions      = ".gif",".jpg",".jpeg",".png",".tif",".tiff",".bmp",".dib",".wmf",".emf",".emz",".svg",".svgz",".dwg",".dxf",".crw",".cr2",".raw",".eps",".ico",".pcx"
			$OfficeExtensions     = ".pdf",".doc",".docx",".xls",".xlsx",".ppt",".pptx"
			$OfficeExtensions2    = ".rtf",".txt",".csv",".xml",".mht",".mhtml",".htm",".html",".xps", `
									".dot",".dotx",".docm",".dotm",".odt",".wps", `
									".xlt",".xltx",".xlsm",".xlsb",".xltm",".xla",".ods",`
									".pot",".potx",".pptm",".potm",".pps",".ppsx",".ppsm",".odp", `
									".pub",".mpp",".vsd",".vsdx",".vsdm",".vdx",".vssx",".vssm",".vsx",".vstx",".vst",".vstm",".vsw",".vdw"
			#$OfficeExtensions    += $OfficeExtensions2
			$JunkExtensions       = ".tmp",".temp",".lock"
			$ArchiveExtensions    = ".zip",".7z",".rar",".cab",".iso",".001",".ex_"
			$ScriptExtensions     = ".ps1",".vbs",".vbe",".cmd",".bat",".php",".hta",".ini",".inf",".reg",".asp",".sql",".vb",".js",".css",".kix",".au3"
			$AllExtensions        = $MultimediaExtensions + $ImageExtensions + $OfficeExtensions + $JunkExtensions + $ArchiveExtensions + $ScriptExtensions
			$extension = $null
			
		}
        process{
			Write-Verbose "Creating file Name"
	 
			switch ($filesType) {
				"Multimedia" {$extension = $MultimediaExtensions | Get-Random}
				"Image"      {$extension = $ImageExtensions | Get-Random}
				"Office"     {$extension = $OfficeExtensions | Get-Random }
				"Office2"    {$extension = $OfficeExtensions2 | Get-Random }
				"Junk"       {$extension = $JunkExtensions | Get-Random}
				"Archive"    {$extension = $ArchiveExtensions | Get-Random}
				"Script"     {$extension = $ScriptExtensions | Get-Random}
				default      {$extension = $AllExtensions | Get-Random }
			}
			Get-Verb | Select-Object verb | Get-Random -Count 2 | %{$Name+= $_.verb}
			$FullName = $NamePrefix + $name + $extension
			Write-Verbose "File name created : $FullName"
			Write-Progress @Progress -CurrentOperation "Created file Name : $FullName"
        }
        end {
			return $FullName
        }
    }
}
#----------------Process-----------------------------------------------
 
process {
	If ($TotalSize -match '^d+$') { [string]$TotalSize += "MB" } #if TotalSize isNumeric (did not contain a byte designation, assume MB
    $Progress.Status="Creating $NumberOfFiles files totalling $TotalSize"
    Write-Progress @Progress
 
    Write-Verbose "Total Size is $TotalSize"
    $FileSize = $TotalSize / $NumberOfFiles
    $FileSize = [Math]::Round($FileSize, 0)
    Write-Verbose "Average file size of $FileSize"
    $FileSizeOffset = [Math]::Round($FileSize/$NumberOfFiles, 0)
    Write-Verbose "file size offset of $FileSizeOffset"
    $FileSize = $FileSizeOffset*$NumberOfFiles/2
    Write-Verbose "Beginning file size of $FileSize"
 
    while ($FileNumber -lt $NumberOfFiles) {
        $FileNumber++
        If ($FileNumber -eq $NumberOfFiles) { 
            $FileSize = $TotalSize - $TotalFileSize
            Write-Verbose "Setting last file to size $FileSize"
        }
        $TotalFileSize = $TotalFileSize + $FileSize
        $FileName = Create-FileName -filesType $filesType
        Write-Verbose "Creating : $FileName of $FileSize"
        $Progress.Status="Creating $NumberOfFiles files totalling $TotalSize.  Run time $(New-TimeSpan -Start $StartTime -end $(Get-Date))"
        Write-Progress @Progress -CurrentOperation "Creating file $FileNumber of $NumberOfFiles : $FileName is $FileSize bytes." -PercentComplete ($FileNumber/$NumberOfFiles*100)
        $FullPath = Join-Path $path -ChildPath $FileName
#        Write-Verbose "Generating file : $FullPath of $Filesize"
        try{
            ## Creates Fake empty file with FileSize
            $buffer=New-Object byte[] $FileSize  
            $fi=[io.file]::Create($FullPath)
            $fi.Write($buffer,0,$buffer.length)
            $fi.Close()
			
			## Add random data into file
            $stream = [System.IO.StreamWriter]::new($FullPath)	
			$counter = 100
            $newwords = @()
            for($i=0; $i -lt $counter; $i++){
              $randomword = Get-Random -InputObject $words
              $newwords += $randomword
            } 
            $finaldata = $newwords -join ' ' 
		
            foreach ($p in $finaldata) {
			$stream.WriteLine("$p")}
			$stream.close()
		}
        catch{
            $_
        }
 
        $FileCreated = ""
        $Properties = @{'FullPath'=$FullPath;'Size'=$FileSize}
		$FileCreated = New-Object -TypeName psobject -Property $properties
        $AllCreatedFilles += $FileCreated
        Write-verbose "$($AllCreatedFilles) created $($FileCreated)"
        Write-Progress @Progress -CurrentOperation "Creating file $FileNumber of $NumberofFiles : $FileName is $FileSize bytes.  Done." -PercentComplete ($FileNumber/$NumberOfFiles*100)

   		$FileSize = ([Math]::Round($FileSize, 0)) + $FileSizeOffset
    }
}
end{
    Write-Output $AllCreatedFilles
    Write-Output "Start     time: $StartTime"
    Write-Output "Execution time: $(New-TimeSpan -Start $StartTime -end $(Get-Date))" 
}
}

 
Create-RandomFiles -TotalSize 200KB -NumberOfFiles 12 -Path C:\Users\Administrator\Desktop -NamePrefix '~' -filesType 'Office2'