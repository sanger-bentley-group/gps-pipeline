// Check if Singularity images are already pulled, otherwise pull non-existing images one by one
void singularityPreflight(Path configPath, String singularityCacheDir) {
    log.info("Checking if all the Singularity images are available at ${singularityCacheDir}\n")

    // Get names of all images
    File configFile = configPath.toFile()
    containers = [] as Set
    configFile.eachLine { line ->
        matcher = line =~ /\s+container\s?=\s?'(.+)'/
        if (matcher.matches()) {
            containers.add(matcher.group(1))
        }
    }

    // Create the directory for saving images if not yet existed
    File cacheDir = new File(singularityCacheDir)
    cacheDir.exists() || cacheDir.mkdirs()

    // Get images that needs to be downloaded
    toDownload = [] as Set
    containers.each { container ->
        targetName = container.replace(':', '-').replace('/', '-') + '.img'
        targetFile = new File (singularityCacheDir + File.separator + targetName)
        if (!targetFile.exists()) {
            toDownload.add([container, targetName])
        }
    }

    // Download all the images that do not exist yet
    toDownload.each { container, targetName ->
        log.info("${container} is not found. Pulling now...")
        process = "singularity pull --dir ${singularityCacheDir} ${targetName} docker://${container}".execute()
        process.waitFor()

        if (process.exitValue()) {
            log.info("${container} cannot be pulled successfully. Check your Internet connection and re-run the pipeline.\n")
            System.exit(1)
        }

        log.info("${container} is pulled and saved as ${targetName}\n")
    }

    log.info("All images are ready. The workflow will resume.\n")
}