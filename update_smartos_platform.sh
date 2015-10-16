#!/usr/bin/env bash
# SmartOS platform image updater for netboot environments | tamas@gerczei.eu
ME=$(basename ${0%.sh})
DESTDIR="/var/tmp/"
LOCATION="us-east"
FILENAME="platform-latest.tgz"
TFTPROOT="/var/lib/tftpboot"
URL="https://${LOCATION}.manta.joyent.com/Joyent_Dev/public/SmartOS/${FILENAME}"
REPLY=$(curl ${URL} -z ${DESTDIR:-/var/tmp}/${FILENAME} -o ${DESTDIR:-/var/tmp}/${FILENAME} -s -L -w %{http_code} -C - 2>/dev/null)

case $REPLY in
		200)
			# OK, new image downloaded
			# extract it
			tar xf ${DESTDIR:-/var/tmp}/${FILENAME} -C ${TFTPROOT}/smartos --transform 's!^platform-!!' 2>/dev/null

			if [ $? -ne 0 ]
				then
					# failed to extract, force the process to repeat next time and bail out
					rm ${DESTDIR:-/var/tmp}/${FILENAME}
					exit 1
			fi

			# determine which one it is
			shopt -s extglob
			LASTDIR="$(ls -dt ${TFTPROOT}/smartos/+([0-9])T+([0-9])Z | head -1)"

			# re-organize it slightly
			mkdir ${LASTDIR}/platform
			mv ${LASTDIR}/i86pc ${LASTDIR}/platform

			# set ownership
			chown -R tftp:tftp ${LASTDIR}

			# generate iPXE configuration
			TODAY="$(date '+%d%m%y')"
			if [ -f ${TFTPROOT}/smartos.ipxe ]
				then
					# secure a copy of the previous configuration file
					cp ${TFTPROOT}/smartos.ipxe ${TFTPROOT}/smartos.ipxe.${TODAY}
			fi
			sed -e "s/\$release/$(basename ${LASTDIR})/g" < ${TFTPROOT}/smartos.ipxe.tpl > ${TFTPROOT}/smartos.ipxe

			# housekeeping and logging
			logger -t $ME -p user.debug created ${LASTDIR} and ${TFTPROOT}/smartos.ipxe
			logger -t $ME -p user.debug removed $(find ${TFTPROOT}/smartos -maxdepth 1 -type d -mtime +${KEEPDAYS:-28} -printf '%f ' -exec rm -r {} \;)
			;;

		304)
			# NOT MODIFIED, no update
			;;
		*)
			# WTF
			echo "server returned $REPLY, I cannot handle that"
			exit 1
			;;
esac

exit 0
