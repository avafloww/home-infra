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

@app.get('/hosts/{host}/managed_vms')
async def get_host_managed_vms_local(host: str):
  if host not in valid_hosts:
    raise HTTPException(status_code=404, detail='invalid host')

  stdout, stderr = ssh_exec(valid_hosts[host], f'cat {managed_vms_local_file}')
  try:
    managed_vms = json.loads(stdout)
  except:
    raise HTTPException(status_code=500, detail=stderr)

  return {
    'host': valid_hosts[host],
    'managed_vms': managed_vms,
    'stdout': stdout,
    'stderr': stderr,
  }

@app.post('/hosts/{host}/managed_vms')
async def set_host_managed_vms_local(host: str, managed_vms: dict):
  if host not in valid_hosts:
    raise HTTPException(status_code=404, detail='invalid host')

  # reject if the top level has any key other than server-anima
  if len(managed_vms.keys()) != 1 or 'server-anima' not in managed_vms:
    raise HTTPException(status_code=400, detail='invalid managed_vms')

  managed_vms = json.dumps(managed_vms)
  stdout, stderr = ssh_exec(valid_hosts[host], f'echo \'{managed_vms}\' > {managed_vms_local_file}')

  print('running ansible to reconfigure')

  # lol, lmao
  os.system(f'nohup bash -c " \
              cd {ansible_dir} && \
              ./run.sh generate_tfvars.yml && \
              cd terraform && \
              terraform apply -auto-approve && \
              ssh {ssh_user}@{valid_hosts[host]} \'sudo virsh start server-anima\' && \
              cd {ansible_dir} && \
              ./run.sh update_ml_lab_motd.yml \
            "  & ')

  return {
    'host': valid_hosts[host],
    'stdout': stdout,
    'stderr': stderr
  }

if __name__ == '__main__':
  uvicorn.run(app, host='0.0.0.0', port=8474)
