import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildSteps.script

/*
 * Versioned settings (Kotlin DSL) of the Root project of the local TeamCity.
 * local-cluster/configure-teamcity.sh points TeamCity at them, and Tilt
 * publishes edits to this directory, which TeamCity picks up in about a
 * minute. Settings are read-only in the UI: change them here.
 */

version = "2026.1"

project {
    description = "Settings from local-cluster/.teamcity"

    features {
        // Starts agents as pods from the Deployments of the teamcity-agents
        // chart, authenticating as its ServiceAccount.
        kubernetesCloudProfile {
            id = "LocalCluster"
            name = "Local cluster"
            apiServerURL = "https://kubernetes.default.svc"
            caCertData = DslContext.getParameter("kubernetesCaCert")
            namespace = "teamcity-agents"
            authStrategy = token {
                token = "credentialsJSON:kubernetes-agents-token"
            }
            // The main node's own Service, from the teamcity chart.
            serverURL = "http://main-node-0.teamcity"
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
    description = "A pipeline: build, three test shards in parallel, then release"

    sequential {
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
            name = "Build"
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
            name = "Test"
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
