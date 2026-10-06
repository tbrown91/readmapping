process STAR_ALIGN {
    tag "$meta.id"
    label "process_high"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/26/268b4c9c6cbf8fa6606c9b7fd4fafce18bf2c931d1a809a0ce51b105ec06c89d/data' :
        'community.wave.seqera.io/library/htslib_samtools_star_gawk:ae438e9a604351a4' }"
  
    input:
    tuple val(meta),  path(cram),  path(crai), val(rglines)
    tuple val(meta2), path(index), path(assembly)
    tuple val(chunkn), val(range)

    output:
    tuple val(meta), path("*.star.bam"), emit: bam
    tuple val("${task.process}"), val('star'), eval('STAR --version | sed -e "s/STAR_//g"'), emit: versions_star, topic: versions
    tuple val("${task.process}"), val('samtools'), eval('samtools --version | head -1 | sed -e "s/samtools //"'), emit: versions_samtools, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix  = task.ext.prefix ?: "${cram}.${chunkn}.${meta.id}"
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def args3 = task.ext.args3 ?: ""
    def args4 = task.ext.args4 ?: ''
    """

    samtools view -b -h -o unaligned.bam ${cram}
    STAR \\
        --genomeDir $index \\
        --runThreadN $task.cpus \\
        --outFileNamePrefix $prefix. \\
        $args \\
        --readFilesCommand "samtools view -h" \\
        --readFilesIn unaligned.bam

    samtools fixmate ${args2} ${prefix}.Aligned.out.bam - |\\
        samtools view -h ${arg3} |\\
        samtools sort ${args4} -@${task.cpus} -T ${prefix}_tmp -o ${prefix}.star.bam -
    
    rm unaligned.bam
    rm ${prefix}.Aligned.out.bam
    """

    stub:
    def prefix  = task.ext.prefix ?: "${cram}.${chunkn}.${meta.id}"
    """
    touch ${prefix}.star.bam
    """
}
