[nodes]
%{ for index, ip in nodes ~}
${prefix-nodes}-${index} ansible_host=${ip} ansible_user=${user}
%{ endfor ~}

[controllers]
%{ for index, ip in controllers ~}
${prefix-controllers}-${index} ansible_host=${ip} ansible_user=${user}
%{ endfor ~}