from fastapi import FastAPI, HTTPException
import uvicorn
import paramiko
import json
import os

def ssh_exec(host: str, command: str):
  ssh = paramiko.SSHClient()
  ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
  ssh.connect(host, username=ssh_user)
  _, stdout, stderr = ssh.exec_command(command)

  stdout = stdout.read().decode('utf-8')
  stderr = stderr.read().decode('utf-8')

  return (stdout, stderr)

# load config from config.json
with open(f'{os.getcwd()}/config.json') as f:
  config = json.load(f)
  if 'managed_vms_local_file' not in config:
    raise Exception('managed_vms_local_file not defined in config.json')
  valid_hosts = config['valid_hosts'] # hostname -> ip
  managed_vms_local_file = config['managed_vms_local_file'] # string
  ssh_user = config['ssh_user'] # string
  ansible_dir = config['ansible_dir'] # string

# bootstrap the app
app = FastAPI()

@app.get('/')
async def ping():
  return {'ping': 'pong'}

@app.post('/anima/claim/{gpu_count}')
async def claim_anima(gpu_count: int):
  ssh_hostname = valid_hosts['krile']
  pci_devices = []

  if gpu_count != 1 and gpu_count != 2:
    raise HTTPException(status_code=400, detail='invalid gpu_count - must be either 1 or 2')

  if gpu_count == 2:
    virsh_list, _ = ssh_exec(ssh_hostname, 'sudo virsh list --name --state-running')
    virsh_list = virsh_list.split('\n')
    for vm in virsh_list:
      if vm.startswith('workstation-'):
        raise HTTPException(status_code=409, detail=f'cannot claim 2 gpus: pre-empted by {vm}')
    pci_devices.append('gpu1-rtx3090')

  pci_devices.append('gpu2-rtx3090')

  managed_vms = json.dumps({
    'server-anima': {
      'pci_devices': pci_devices
    }
  })

  stdout, stderr = ssh_exec(ssh_hostname, f'echo \'{managed_vms}\' > {managed_vms_local_file}')

  print('running ansible to reconfigure')

  # lol, lmao
  os.system(f'nohup bash -c " \
              cd {ansible_dir} && \
              ./run.sh generate_tfvars.yml && \
              cd terraform && \
              terraform apply -auto-approve && \
              ssh {ssh_user}@{ssh_hostname} \'sudo virsh start server-anima\' && \
              cd {ansible_dir} && \
              ./run.sh update_ml_lab_motd.yml \
            "  & ')

  return {
    'host': ssh_hostname,
    'status': 'claim in progress',
    'stdout': stdout,
    'stderr': stderr
  }

@app.post('/anima/unclaim')
async def unclaim_anima():
  ssh_hostname = valid_hosts['krile']
  stdout, stderr = ssh_exec(ssh_hostname, f'sudo virsh destroy server-anima')

  return {
    'host': ssh_hostname,
    'status': 'success',
    'stdout': stdout,
    'stderr': stderr
  }

if __name__ == '__main__':
  uvicorn.run(app, host='0.0.0.0', port=8474)
