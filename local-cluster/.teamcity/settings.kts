import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildSteps.script

version = "2026.1"

project {
    features {
        kubernetesCloudProfile {
            id = "LocalCluster"
            name = "Local cluster"
            apiServerURL = "https://kubernetes.default.svc"
            caCertData = DslContext.getParameter("kubernetesCaCert")
            namespace = "teamcity-agents"
            authStrategy = token {
                token = "credentialsJSON:kubernetes-agents-token"
            }
            serverURL = "http://teamcity.teamcity"
            terminateIdleMinutes = 10
        }
        kubernetesCloudImage {
            id = "MinimalAgent"
            profileId = "LocalCluster"
            agentNamePrefix = "minimal"
            maxInstancesCount = 3
            podSpecification = deploymentTemplate {
                deploymentName = "teamcity-agents-minimal"
            }
        }
    }

    subProject(Examples)
}

object Examples : Project({
    name = "Examples"

    // Run every build each time, instead of reusing ones at the same revision.
    sequential({ reuseBuilds = ReuseBuilds.NO }) {
        buildType(Build)
        parallel {
            (1..3).forEach { buildType(Test(it)) }
        }
        buildType(Release)
    }.buildTypes().forEach { buildType(it) }
})

object Build : BuildType({
    name = "Build"
    artifactRules = "app.txt"
    steps {
        script {
            scriptContent = """
                echo "Built by %teamcity.agent.name% in build %build.number%" > app.txt
                sleep 10
            """.trimIndent()
        }
    }
})

class Test(shard: Int) : BuildType({
    id("Test$shard")
    name = "Test $shard"
    steps {
        script {
            scriptContent = """
                cat app.txt
                sleep 20
                echo "Shard $shard passed on %teamcity.agent.name%"
            """.trimIndent()
        }
    }
    dependencies {
        artifacts(Build) {
            artifactRules = "app.txt"
        }
    }
})

object Release : BuildType({
    name = "Release"
    type = BuildTypeSettings.Type.COMPOSITE
})
