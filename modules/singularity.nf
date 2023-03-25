void singularityPreflight(Path configPath, String singularityCacheDir) {
    File configFile = configPath.toFile()
    containers = [] as Set
    configFile.eachLine { line ->
        matcher = line =~ /\s+container\s?=\s?'(.+)'/
        if (matcher.matches()) {
            containers.add(matcher.group(1))
        }
    }

    File cacheDir = new File(singularityCacheDir)
    cacheDir.exists() || cacheDir.mkdirs()

    // TODO
    // Move pulls to another loop
    containers.each { container ->
        targetName = container.replace(':', '-').replace('/', '-') + '.img'
        targetFile = new File (singularityCacheDir + File.separator + targetName)
        if (!targetFile.exists()) {
            log.info("${container} not found in ${singularityCacheDir}. Pulling now...")
            process = "singularity pull --dir ${singularityCacheDir} ${targetName} docker://${container}".execute()
            process.waitFor()
            // TODO
            // Check exit value
            println(process.exitValue())
            log.info("${container} is pulled and saved as ${targetName}")
        }
    }
}