
$iconFontFirstCP = 0xf0001
$iconFontLastCP = 0xf13fe

cd $PSScriptRoot
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
Add-Type -Path ./ZiLib.dll


Function New-ZiFontV5 {
  param (
    $characterFont,
    $iconFont,
    [byte[]]$size,
    $Codepage = [ZiLib.CodePageIdentifier]::utf_8,
    $Path
  )


  $iconSet = @()
  for ($i = $iconFontFirstCP; $i -le $iconFontLastCP; $i++) {
    $iconSet += $i
  }
    $locationText = [System.Drawing.PointF]::new(0,0)
    $locationIcon = [System.Drawing.PointF]::new(0,8)

    Write-Host "> Codepage $codepage"
    foreach($fontsize in $size){
            Write-Host ">> $characterFont $fontsize" -ForegroundColor Cyan

            $file = Get-ChildItem $characterFont
            $newfontsize = $fontsize

            # Check if fontname is a otf/ttf file
            if ((($file.Extension -eq ".ttf") -Or ($file.Extension -eq ".otf")) -and ($file.Exists))
            {
                $pfc = [System.Drawing.Text.PrivateFontCollection]::new()
                $pfc.AddFontFile($characterFont)
                $font = [System.Drawing.Font]::new($pfc.Families[0], $newfontsize, "regular", [System.Drawing.GraphicsUnit]::pixel );

                # also for icons
                # $pfc.AddFontFile("D:\NextionFonts\Font-Awesome\otfs\Font Awesome 5 Brands-Regular-400.otf")
                # $pfc.AddFontFile("D:\NextionFonts\Font-Awesome\otfs\Font Awesome 5 Free-Solid-900.otf")
                # $pfc.AddFontFile("D:\NextionFonts\Font-Awesome\otfs\Font Awesome 5 Free-Regular-400.otf")

                $pfc.AddFontFile($iconFont)

                # $brandfont = $pfc.families | ? { $_.name -like "*brands*"} | select -First 1
                # $freeregularfont =  $pfc.families | ? { $_.name -like "*free regular*"} | select -First 1
                # $freesolidfont = $pfc.families | ? { $_.name -like "*free solid*"} | select -First 1
                $materialiconfont = $pfc.families | ? { $_.name -like "*material design icons*"} | Select-Object -First 1
                # $pfc.families
            } else {
                $font = [ZiLib.Extensions.BitmapExtensions]::GetFont($characterFont,$newfontsize,"Regular")
            }

            $i=0
            while ([math]::Abs($fontsize - $font.Height) -gt 0.1 -and $i++ -lt 10)
            {
                $newfontsize += ($fontsize - $font.Height) / 2 * $newfontsize / $font.Height;
                Write-Host -ForegroundColor Gray $newfontsize
                $font = [System.Drawing.Font]::new($font.fontfamily, $newfontsize, "regular", [System.Drawing.GraphicsUnit]::pixel );
            }

            $f = [ZiLib.FileVersion.V5.ZiFontV5]::new() #$codepage, $fontsize, 0);
            $f.CharacterHeight = $fontsize
            $f.CodePage = $codepage
            $f.Version = 5

            $stopwatch = [system.diagnostics.stopwatch]::StartNew()
            $timerDraw = [system.diagnostics.stopwatch]::New()
            $timerEncode = [system.diagnostics.stopwatch]::New()
            $timerInsert =  [system.diagnostics.stopwatch]::New()

        <#    foreach ($ch in $f.CodePage.CodePoints ) {

                #$bmp = [ZiLib.CharBitmap]::new($ch);

                $bytes = [bitconverter]::GetBytes([uint16]$ch)
                if ($f.CodePage.CodePageIdentifier -eq "UTF_8") {
                if ($ch -lt 0x00d800 -or $ch -gt 0x00dfff) {
                        $txt =  [Char]::ConvertFromUtf32([uint32]($ch + $codepoint.delta))} else {$txt="?"}
                } else {
                    if ($ch -gt 255) {
                        $txt = $f.CodePage.Encoding.GetChars($bytes,0,2)
                    } else {
                        $txt = $f.CodePage.Encoding.GetChars($bytes,0,1)
                    }
                }

                $found = $false
                  if ($ch -ge $iconFontFirstCP) {

                    if ($ch -in $iconSet) {
                        $found=$true;
                        $font = [System.Drawing.Font]::new($materialiconfont, $newfontsize, "regular", [System.Drawing.GraphicsUnit]::pixel )
                    }


                        # if ($ch -in $brands) { $found=$true;               $font = [System.Drawing.Font]::new($brandfont, $newfontsize, "regular", [System.Drawing.GraphicsUnit]::pixel )}
                        # if ($ch -in $solid) {  $found=$true;               $font = [System.Drawing.Font]::new($freesolidfont, $newfontsize, "regular", [System.Drawing.GraphicsUnit]::pixel )}
                        # if ($ch -in $regular) { $found=$true;                $font = [System.Drawing.Font]::new($freeregularfont, $newfontsize, "regular", [System.Drawing.GraphicsUnit]::pixel )}
                        
                        # if ($ch -ge 0xf8A0) {Continue}
                        #$chent.Code = 0xf000 + $ch2++
                    $font.name
                    }

                # Create Character Bipmap
                
                #$timerDraw.start()
                #$bmp = [ZiLib.Extensions.BitmapExtensions]::DrawString($txt, $font, $fontsize, 0, 0, 0)
                #$timerDraw.stop()

                #$timerEncode.start()
                #$bytes = [ZiLib.FileVersion.V5.BinaryTools]::BitmapTo3BppData($bmp)
                #$timerEncode.stop()
                
                #$timerInsert.start()
                #$character = [ZiLib.FileVersion.Common.ZiCharacter]::FromBytes($f, $ch, $bytes, $bmp.width, 0, 0)


                if ($found){
                    $character = [ZiLib.FileVersion.Common.ZiCharacter]::FromString($f, $ch, $font, $locationIcon, $txt)
                }else {
                    $bitmap = [System.Drawing.Bitmap]::new(1,$fontsize);
                    $character = [ZiLib.FileVersion.Common.ZiCharacter]::FromBitmap($f,$ch,$bitmap,0,0)
                }

                if ($ch -ge $iconFontFirstCP) {
                    $f.AddCharacter($ch, $character)
                }

                if ($ch -ge 127 -and $ch -lt 160) {
                    # variable width spaces
                    $bitmap = [System.Drawing.Bitmap]::new($ch-126,$fontsize);
                    $character = [ZiLib.FileVersion.Common.ZiCharacter]::FromBitmap($f,$ch,$bitmap,0,0)
                    $f.AddCharacter($ch, $character)
                } elseif ($ch -ge 0x20 -and $ch -le 0xff) {
                    # normal text
                    $character = [ZiLib.FileVersion.Common.ZiCharacter]::FromString($f, $ch, $font, $locationText, $txt)
                    $f.AddCharacter($ch, $character)
                }

                
                $timerInsert.stop()
            }#>

            # Letters
            foreach ($ch in 32..255) {
                   # normal text
                    $bytes = [bitconverter]::GetBytes([uint16]$ch)
                    if ($f.CodePage.CodePageIdentifier -eq "UTF_8") {
                    if ($ch -lt 0x00d800 -or $ch -gt 0x00dfff) {
                            $txt =  [Char]::ConvertFromUtf32([uint32]($ch + $codepoint.delta))} else {$txt="?"}
                    } else {
                        if ($ch -gt 255) {
                            $txt = $f.CodePage.Encoding.GetChars($bytes,0,2)
                        } else {
                            $txt = $f.CodePage.Encoding.GetChars($bytes,0,1)
                        }
                    }
                    #$txt

                    $character = [ZiLib.FileVersion.Common.ZiCharacter]::FromString($f, $ch, $font, $locationText, $txt)
                    $f.AddCharacter($ch, $character)
            }

            $font = [System.Drawing.Font]::new($materialiconfont, $newfontsize, "regular", [System.Drawing.GraphicsUnit]::pixel )
            # Icons
            foreach ($ch in 0xf0001..0xf13fe) {
                    # mdi
                    $txt =  [Char]::ConvertFromUtf32([uint32]($ch))
                    #$txt

                    $character = [ZiLib.FileVersion.Common.ZiCharacter]::FromString($f, $ch-0xE2001 , $font, $locationText, $txt)
                    $f.AddCharacter($ch, $character)
            }


            $stopwatch.Elapsed.TotalSeconds
            $timerDraw.Elapsed.TotalSeconds
            $timerEncode.Elapsed.TotalSeconds
            $timerInsert.Elapsed.TotalSeconds

            $file = Get-Item $characterFont
            # $filename = "HMI " + $file.basename
            $filename = $file.basename
            $f.Name = $filename

            New-Item -ItemType Directory -Path $path -Force
            $outfile = Join-Path -Path $path -ChildPath ("{0} {1} ({2}).zi" -f $filename,$fontsize,$Codepage)
            $f.Save($outfile)
            $stopwatch.Elapsed.TotalSeconds

            $stopwatch.stop()


            $source = Split-Path -Parent $file
            $dest = Split-Path -Parent $path
            foreach ($license in "*.txt","README","README.*","DESCRIPTION.en_us.html","HISTORY","NEWS") {
                if (Test-Path "$source\$license") {
                    Copy-Item -Path "$source\$license" -Destination $dest
                }
            }


           #New-ZiFontPreview $outfile

      }
}

$cp = [ZiLib.CodePageIdentifier]::utf_8
# $size = @(12,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,42,44,46,48,50,52,54,56,58,60,62,64,66,68,70,72,74,76,78,80)

# $size = @(24,32,48)


$size = @(64)
$outfile= "output" | Resolve-Path | % { $_.Path }
$characterFont = "./NotoSans-Regular.ttf" | Get-ChildItem | % { $_.FullName }
$iconFont = "./MaterialDesignIconsDesktop.ttf" | Get-ChildItem | % { $_.FullName }


New-ZiFontV5 -characterFont $characterFont -iconFont $iconFont -size $size -Codepage $cp -Path $outfile
