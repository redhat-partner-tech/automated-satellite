#!/bin/bash
rpm -qa --queryformat '%{vendor}:%{name}\n' > /tmp/rpm_vendor_list.out
RPM_VENDOR_LIST=$(grep 'Oracle America' /tmp/rpm_vendor_list.out)
if [[ -z "$RPM_VENDOR_LIST" ]]; then
    echo "No Oracle America packages present"
else
    grep 'Oracle America' /tmp/rpm_vendor_list.out
    rm -rf /tmp/rpm_vendor_list.out
fi
