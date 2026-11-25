// TODO nf-core: If in doubt look at other nf-core/modules to see how we are doing things! :)
//               https://github.com/nf-core/modules/tree/master/modules/nf-core/
//               You can also ask for help via your pull request or on the #modules channel on the nf-core Slack workspace:
//               https://nf-co.re/join
// TODO nf-core: A module file SHOULD only define input and output files as command-line parameters.
//               All other parameters MUST be provided using the "task.ext" directive, see here:
//               https://www.nextflow.io/docs/latest/process.html#ext
//               where "task.ext" is a string.
//               Any parameters that need to be evaluated in the context of a particular sample
//               e.g. single-end/paired-end data MUST also be defined and evaluated appropriately.
// TODO nf-core: Software that can be piped together SHOULD be added to separate module files
//               unless there is a run-time, storage advantage in implementing in this way
//               e.g. it's ok to have a single module for bwa to output BAM instead of SAM:
//                 bwa mem | samtools view -B -T ref.fasta
// TODO nf-core: Optional inputs are not currently supported by Nextflow. However, using an empty
//               list (`[]`) instead of a file can be used to work around this issue.

process SMARTPCA {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/07/073a87532f88845132a575101cfb4d0025786ac1f3fb56314938a2523d0d0af8/data':
        'community.wave.seqera.io/library/eigensoft:9.0.0--1ff6eea74cf655bf' }"

    input:
    tuple val(meta), path(geno), path(snp), path(ind)
    tuple val(meta2), path(poplist)
    tuple val(meta3), path(badsnpname)
    tuple val(meta4), path(elllistname)
    tuple val(meta5), path(xregionname)

    output:
    tuple val("${task.process}"), val('smartpca'), eval("smartpca -v 2>/dev/null | grep '##' | cut -f4 -d ' '"), topic: versions, emit: versions_smartpca
    tuple val(meta), path("*.evec"), emit: evec
    tuple val(meta2), path("*.eval"), emit: eval
    tuple val(meta3), path("*.log"), emit: log
    tuple val(meta4), path("*.txt"), emit: ellout, optional:true
    tuple val(meta5), path("*.weight"), emit: weight, optional:true
    tuple val(meta6), path("*.outlier"), emit: outlieroutname, optional:true
    tuple val(meta7), path("*.phylip"), emit: phylipoutname, optional:true


    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    cat <<EOF > ${prefix}.par
    genotypename: ${geno}
    snpname: ${snp}
    indivname: ${ind}
    evecoutname: ${evec}
    evaloutname: ${eval}
    ${args}
    EOF

    smartpca \\
        -p ${prefix}.par > ${log}
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo $args
    
    touch ${prefix}.par
    touch ${prefix}.eval 
    touch ${prefix}.evec
    touch ${prefix}.log
    """
}
