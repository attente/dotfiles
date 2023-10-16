import process from 'node:process'
import net from 'node:net'
import readline from 'node:readline/promises'

const socketDir = `${process.env.XDG_RUNTIME_DIR}/hypr/${process.env.HYPRLAND_INSTANCE_SIGNATURE}`

const watchedEvents = [
  'activewindow',
  'closewindow',
  'createworkspace',
  'destroyworkspace',
  'monitoradded',
  'monitorremoved',
  'movewindow',
  'moveworkspace',
  'openwindow',
  'windowtitle',
  'workspace'
]

interface Monitor {
  id: number
  name: string
  activeWorkspace: { id: number }
}

interface Workspace {
  id: number
  monitor: string
  lastwindowtitle: string
}

function request(command: 'monitors', ...args: string[]): Promise<Monitor[]>
function request(command: 'workspaces', ...args: string[]): Promise<Workspace[]>
function request(command: string, ...args: string[]): Promise<any> {
  const socket = net.connect(`${socketDir}/.socket.sock`)

  return new Promise(resolve => {
    socket.on('connect', () => {
      let output = ''

      const reader = readline.createInterface(socket)

      reader.on('line', line => {
        output += line
      })

      reader.on('close', () => {
        resolve(JSON.parse(output))
      })

      socket.write(`j/${command}${args.flatMap(arg => ` ${arg}`)}`)
    })
  })
}

function isWatchedEvent(line: string): boolean {
  return watchedEvents.some(event => line.startsWith(`${event}>>`))
}

async function getWorkspaces(): Promise<string> {
  const monitors = await request('monitors')
  const workspaces = await request('workspaces')

  const monitorIdMap = new Map(monitors.map(({ id, name }) => [name, id]))
  const monitorMap = new Map(monitors.map(monitor => [monitor.id, monitor]))
  const workspaceMap = new Map(workspaces.map(workspace => [workspace.id, workspace]))

  const lastMonitor = monitors.reduce((index, monitor) => Math.max(index, monitor.id), 0)
  const lastWorkspace = workspaces.reduce((index, workspace) => Math.max(index, workspace.id), 0)

  const monitorResult = (i: number) => {
    return monitorMap.get(i)?.activeWorkspace.id
  }

  const workspaceResult = (i: number) => {
    const workspace = workspaceMap.get(i)
    return `{"id":${i},"monitor":${workspace ? monitorIdMap.get(workspace.monitor) ?? null : null},"lastwindowtitle":${JSON.stringify(workspace?.lastwindowtitle ?? null)},"active":${monitors.some(monitor => monitor.activeWorkspace.id === i)}}`
  }

  const monitorResults = [...Array(1 + lastMonitor).keys()].map(i => monitorResult(i) ?? null)
  const workspaceResults = [...Array(lastWorkspace).keys()].map(i => workspaceResult(1 + i))
  return `{"monitors":${JSON.stringify(monitorResults)},"workspaces":[${workspaceResults.join()}]}`
}

let workspaces = await getWorkspaces()
console.log(workspaces)

const socket = net.connect(`${socketDir}/.socket2.sock`)

socket.on('connect', () => {
  const reader = readline.createInterface(socket)

  reader.on('line', async line => {
    if (isWatchedEvent(line)) {
      const newWorkspaces = await getWorkspaces()
      if (newWorkspaces !== workspaces) {
        console.log(newWorkspaces)
        workspaces = newWorkspaces
      }
    }
  })
})
