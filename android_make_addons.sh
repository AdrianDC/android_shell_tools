#!/bin/bash
ScriptDir=$PWD;
TimeStart=$(date +%s);
source $ScriptDir/android_set_variables.rc;
FilePaths=(\
           "boot.img" \
           "system/app/QuickBoot/QuickBoot.apk" \
           "system/framework/org.cyanogenmod.hardware.jar" \
           "system/lib/modules/*" \
           "system/priv-app/SensorsDoze/SensorsDoze.apk" \
           );
ModulesNames=(\
              "bootimage" \
              "org.cyanogenmod.hardware" \
              "QuickBoot" \
              "SensorsDoze" \
              "sepolicy" \
              );

if [[ "$2" == "manual" ]]; then
  AddonsFile="addons-cm-12.1-"$(date +'%Y%m%d')"-NIGHTLY-$PhoneName-TEST.zip";
else
  AddonsFile="addons-cm-12.1-"$(date +'%Y%m%d')"-NIGHTLY-$PhoneName.zip";
fi;

if [ -f $TargetDir/$AddonsFile ]; then
  rm -f $TargetDir/$AddonsFile;
fi;

cd $AndroidDir/;
source ./build/envsetup.sh;
croot;
breakfast $PhoneName;

LaunchBuild=1;
while [ $LaunchBuild != 0 ];
do

  echo "";
  echo " [ Making the requested libraries ]";
  echo "";
  cd $AndroidDir/;
  mka -j $BuildJobs ${ModulesNames[*]} | tee $LogFile;

  LogMemory=$(grep "make: fork" $LogFile | sort | uniq);
  LogFail=$(grep "fail" $LogFile | sort | uniq);
  LogError=$(grep "Error" $LogFile | sort | uniq);
  LogInstall=$(grep "Install:.*target/product" $LogFile | sort | uniq);
  echo "$LogMemory";
  echo "$LogFail";
  echo "$LogError";
  echo "$LogInstall";
  echo "";

  if [ -z "$(grep "make failed to build" $LogFile | uniq)" ]; then
    LaunchBuild=0;
  else
    LaunchBuild=1;
    printf " Press Enter to restart the build... ";
    if [[ "$1" == "" ]]; then
      read key;
    else
      return;
    fi;
    echo "";
    echo "";
  fi;

done;

cd $OutDir;
FilesList="";
for FilePath in ${FilePaths[*]}
do
  FilesList="$FilesList ./$FilePath";
done;

echo "";
echo " [ Building the new zip ]";
echo "";

cp $ScriptDir/android_files/addons_template.zip $TargetDir/$AddonsFile.unsigned.zip;
zip -g $TargetDir/$AddonsFile.unsigned.zip $FilesList;
SignApkDir=$ScriptDir/android_signapk;
java -jar $SignApkDir/signapk-cm121.jar -w $SignApkDir/testkey.x509.pem $SignApkDir/testkey.pk8 $TargetDir/$AddonsFile.unsigned.zip $TargetDir/$AddonsFile;
rm -f $TargetDir/$AddonsFile.unsigned.zip;

export AndroidResult="$TargetDir/$AddonsFile";

echo "";
echo "  $AddonsFile created.";
echo "";
TimeDiff=$(($(date +%s)-$TimeStart));

echo "";
echo " [ Done in $TimeDiff secs ]";
echo "";
if [[ "$1" == "" ]]; then
  read key;
fi;
echo "";

