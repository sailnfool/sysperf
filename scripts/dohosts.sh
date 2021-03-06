#!/bin/bash
scriptname=${0##*/}
########################################################################
# Copyright (c) 2022 Sea2Cloud Storage, Inc.  All Rights Reserved
# Modesto, CA 95356
#
# dohosts - for a set of hosts, run the complete set of performance
#           tests based on cryptographic hashes.
# Author - Robert E. Novak aka REN
#	sailnfool@gmail.com
#	skype:sailnfool.ren
# License CC by Sea2Cloud Storage, Inc.
# see https://creativecommons.org/licenses/by/4.0/legalcode
# for a complete copy of the Creative Commons Attribution license
#_____________________________________________________________________
# Rev.|Aut| Date     | Notes
#_____________________________________________________________________
# 1.2 |REN|03/09/2022| Added code to delete any prior background
#                    | copies of the created script and then the
#                    | logfiles that they may have left behind.
# 1.1 |REN|03/05/2022| Added command line options for -h and -o
#                    | the -o to eliminate the script do1host and
#                    | execute only on the current host. Also made
#                    | the execution on the currrent host a
#                    | task to survive an ssh disconnect and can
#                    | resume monitoring by tail -f of the log file
# 1.0 |REN|03/04/2022| Initial Release
#_____________________________________________________________________
#########################################################################
scriptfileprefix="/tmp/doscripts_"
scriptfile="${scriptfileprefix}$$.sh"
declare -a hostnames

thismachineonly="FALSE"

USAGE="Run the mcperf script on multiple machines\r\n
\t-h\t\tPrint this message\r\n
\t-o\t\tRun the test scripts ONLY on this machine\r\n
"

########################################################################
# Define all of the optionargs documented in USAGE.
########################################################################
optionargs="ho"

########################################################################
# Process the Command Line options based on the Usage above
########################################################################
while getopts ${optionargs} name
do
  case ${name} in
  h)
    echo -e ${USAGE}
    exit 0
    ;;
  o)
    thismachineonly="TRUE"
    ;;
  \?)
    errecho "-e" "invalid option: ${OPTARG}"
    errecho "-e" ${USAGE}
    exit 1
    ;;
  esac
done
shift $((OPTIND-1))
########################################################################
# End of processing Command Line arguments
########################################################################
if [[ "${thismachineonly}" = "TRUE" ]]
then
  thishost=$(hostname)
  hostnames=("${thishost}")
else
	######################################################################
	# add the systems to the list one at a time.  This makes adding a 
	# single system later an easier process.
	######################################################################
	hostnames=("opti.sea2cloud.com")
	hostnames+=("newdell")
	hostnames+=("Inspiron3185")
	hostnames+=("hplap")
	hostnames+=("PI04-04-02")
	hostnames+=("PI04-08-03")
	hostnames+=("pi3")
fi


########################################################################
# Here is the script that will be run on each of the systems.
########################################################################
cat > ${scriptfile} << EOF
#!/bin/bash
if [[ ! -d /home/rnovak/github/sysperf ]]
then
	mkdir -p /home/rnovak/github
	cd /home/rnovak/github
	git clone git@github.com:sailnfool/sysperf.git
fi
cd ~rnovak/github/sysperf
git pull
sleep 3
make
cd ~rnovak/github/sysperf/results
rm *.csv *.txt *.sh
if [[ ! -d valid_results ]]
then
  mkdir valid_results
fi
if [[ ! -d working_scripts ]]
then
  mkdir working_scripts
fi
allwrapper
localscript=\$(echo "/tmp/script_\$(hostname)\$\$.sh")
echo "#!/bin/bash" > \${localscript}
for script in script*.sh
do
  echo "bash -x \${script}" >> \${localscript}
done
logname="/tmp/\$(hostname)_log_\$\$.txt"
rm -f \${logname}
touch \${logname}
bash -x \${localscript} 2>&1 >> \${logname} &
EOF

########################################################################
# For each of hte systems we will execute the above generated scripts
# Note that the locally generated script is run as a background task
# to insure that it can continue to run.  Note that the output of
# the background script is sent to /tmp/hostname_log_$$.txt so that
# we are able to run a shell on each host and peform "tail -f" on the
# file to monitor the progress on the remote host.
########################################################################
echo "${hostnames[@]}"
for rhost in "${hostnames[@]}"
do
  ######################################################################
  # Make sure we don't ssh to the local host we treat this case later
  ######################################################################
  if [[ ! "${rhost}" = "$(hostname)" ]]
  then
    echo Working on \"${rhost}\"
    ssh ${USER}@${rhost} 'bash -s -x' ${scriptfile} &
  fi
done

########################################################################
# Now execute the script locally
# First, kill any remaining background scripts that might be running.
# Second, kill any copies of the performance test script "mcperf" that
# may have been a child of the ${scriptfileprefix} that we killed.
# Also delete any old copies of the script that may be laying around
########################################################################
killid=$(ps -ax | grep "bash -x ${scriptfileprefix}" | \
  grep -v grep| cut  -d " " -f2)
if [[ ! -z "${killid}" ]]
then
  kill -9 ${killid}
fi
killid=$(ps -ax | grep "bash -x mcperf" | \
  grep -v grep| cut  -d " " -f2)
if [[ ! -z "${killid}" ]]
then
  kill -9 ${killid}
fi

rm -f "${scriptfileprefix}*"

########################################################################
# Delete any old log files
########################################################################
rm -f /tmp/$(hostname)_log_*.txt
bash -x ${scriptfile} &
childid=${!}

########################################################################
# Give the child time to start
# We are waiting until the child creates its log file as an indication
# that the child process has started before we begin waiting with 
# tail -f to watch the logfile
########################################################################
logfile="/tmp/$(hostname)_log_${childid}.txt"
count=1
maxcount=40
sleeptimer=1

while [[ ! -r ${logfile} ]]
do
  sleep ${sleeptimer}
  ((count++))
  if [[ "${count}" -ge "${maxcount}" ]]
  then
    echo "Child failed to start after $((count*sleeptimer))"
    exit 1
  fi
done
tail -f ${logfile}

