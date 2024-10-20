label = "worker-${UUID.randomUUID()}"

// Define parameters upfront using properties(parameters)
properties([
parameters([
[
$class: 'ChoiceParameter',
choiceType: 'PT_MULTI_SELECT', // Allow multiple selections for inventory files
name: 'INVENTORY_FILE',
script: [
$class: 'GroovyScript',
script: [
classpath: [],
sandbox: true,
script: '''
                    // Debugging step: print workspace path and files
                    def workspace = new File("${env.WORKSPACE}/inventory")
                    println "Workspace path: ${workspace.getAbsolutePath()}"

                    if (!workspace.exists()) {
                        println "Inventory folder does not exist"
                        return ["Inventory folder not found"]
                    }

                    def inventoryFiles = []
                    def files = workspace.listFiles()

                    if (files == null || files.size() == 0) {
                        println "No files found in the inventory folder"
                        return ["No files found in inventory"]
                    }

                    files.each { file ->
                        if (file.isFile()) {
                            println "Found inventory file: ${file.getName()}"
                            inventoryFiles.add(file.getName())
                        }
                    }

                    return inventoryFiles
                    '''
                ]
            ]
        ],
        [
            $class: 'ChoiceParameter',
            choiceType: 'PT_SINGLE_SELECT',
            name: 'MODE',
            script: [
                $class: 'GroovyScript',
                script: [
                    classpath: [],
                    sandbox: true,
                    script: '''
                    return [
                        "Python-script",
                        "Playbook",
                        "ping"
                    ]
                    '''
                ]
            ]
        ]
    ])
])

def dockerImage = ""
if (params.MODE == 'Python-script') {
    dockerImage = 'dockerhub-dev.techcombank.com.vn/laudio/pyodbc'
} else {
    dockerImage = 'ansible'
}

podTemplate(
label: label,
cloud: 'dso-workload',
imagePullSecrets: ['nexus-dso-cred'],
containers: [
containerTemplate(
name: 'worker-container',
image: dockerImage,
command: '',
ttyEnabled: true
)
]
) {
node(label) {
    container('worker-container') {
        stage("Checkout SCM"){
            cleanWs()
            checkout scm
        }

        stage('prepare') {
            if (params.MODE.contains('ping')) {
                echo "1" // Replace with actual script logic if needed
            }
            if (params.MODE.contains('Python-script')) {
                sh 'python3 --version'
                sh 'pip3 config set global.index-url https://nexus-dso.techcombank.com.vn/repository/pypi/simple'
                sh 'pip3 install --user -U -i https://nexus-dso.techcombank.com.vn/repository/pypi/simple requests'
                sh 'pip3 install --user -U -i https://nexus-dso.techcombank.com.vn/repository/pypi/simple pandas'
                sh 'python3 ETL.py'
            }
            if (params.MODE.contains('Playbook')) {
                echo "3" // Echo HelloWorld as per the mode
            }
         }

    }
}
}

def getInventoryFiles() {
    def inventoryFiles = []
    def files = new File("${env.WORKSPACE}/inventory").listFiles()
    files.each { file ->
        if (file.isFile()) {
            inventoryFiles << file.getName()
        }
    }
    return inventoryFiles.join('\n')
}
