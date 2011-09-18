# makeItHappen (mih)

  Mih is my humble attempt to solve a problem that has been bugging me for
  a long time: Independence execution of pipelines over different HPC schedulers.
  Let me try to explain better.

  When working with [Next generation](http://blog.goldenhelix.com/?p=423)
  sequencing data you see yourself building pipelines. Most of the pipelines
  I have seen use a set of scripts (typically perl or some shell flavour) to
  drive the executions. Some people tries to group together common blocks of
  code to keep reusing them. Others write [DSLs](http://en.wikipedia.org/wiki/Domain-specific_language)
  to abstract decencies and job submissions.

  Mih should help you to focus on the logic of your pipelines and forget about
  the rest.

## How it works

  Turns out there is a tool out there that perfectly models pipelines and
  offers huge flexibility and features. I am talking about make and particularly
  the [GNU implementation](http://www.gnu.org/software/make/).

  If you use Mih, you will write yourself one (or various) Makefiles to define
  your logic. It will look like a typical makefile but we will make sure every
  [recipe](http://www.gnu.org/software/make/manual/make.html#Introduction)
  executed goes through mih.

  Makefile takes care of all the decencies (after all that's what it was
  designed for). Mih just uses make's information to build, progressively,
  a [directed graph](http://en.wikipedia.org/wiki/Directed_graph). This
  DG contains then all the job information (including dependencies between
  jobs). We call that step: builder.

  Once the DG is build, we can use it to schedule the execution of our pipeline
  instance in our target scheduler. Currently I have coded one target only,
  since that's the scheduler I use the most: [PBS](http://en.wikipedia.org/wiki/Portable_Batch_System).
  I hope other schedulers will be added as more people starts using this tool.

## An example

  Let's write a very simple (but commonly used) pipeline: Aligning next-gen data
  with our beloved [BWA](http://bio-bwa.sourceforge.net/) and postprocessing
  the results with the great set of [Picard tools](http://picard.sourceforge.net/command-line-overview.shtml).

  Our make file may look like this:
    #
    REAL_REF=../indexes/rhemac.masked.classIII.fasta
    N_THREADS=1
    RAM=4g
    LINES_TEST=20001
    TEST_BAM=/stornext/snfs0/next-gen/Illumina/Instruments/700580/101210_SN580_0033_A80Y7TABXX/Data/Intensities/BaseCalls/GERALD_21-12-2010_p-illumina.3/s_5_marked.bam
    TMP=/space1/tmp

    # Hook to mih here
    F=mih builder -c '
    # cmd mem cores name deps
    T=' -m '$(RAM)' -r '$(N_THREADS)' -n '$@' -d '$+'

    all:
      @echo "testing: make INPUT_BAM=input_test.bam REF=../indexes/test.ref.fasta SAMPLE=two two.sorted.dups.bam"
      @echo "example: make INPUT_BAM=../merged.one.bam REF=$(REAL_REF) SAMPLE=one one.sorted.dups.bam"
      @echo "example: make INPUT_BAM=../merged.two.bam REF=$(REAL_REF) SAMPLE=two two.sorted.dups.bam"

    $(SAMPLE).1.sai: $(INPUT_BAM)
      $(F) bwa aln -t$(N_THREADS) $(REF) -b1 $< > $@ $(T)

    $(SAMPLE).2.sai: $(INPUT_BAM)
      $(F) bwa aln -t$(N_THREADS) $(REF) -b2 $< > $@ $(T)

    $(SAMPLE).sam: $(SAMPLE).1.sai $(SAMPLE).2.sai
      $(F) bwa sampe $(REF) $(SAMPLE).1.sai $(SAMPLE).2.sai $(INPUT_BAM) $(INPUT_BAM) > $@ $(T)

    $(SAMPLE).sorted.bam: $(SAMPLE).sam
      $(F) java -Xmx$(RAM) -jar $$PICARD/SortSam.jar SORT_ORDER=coordinate TMP_DIR=$(TMP) INPUT=$< OUTPUT=$@ $(T)

    $(SAMPLE).sorted.dups.bam: $(SAMPLE).sorted.bam
      $(F) java -Xmx$(RAM) -jar $$PICARD/MarkDuplicates.jar INPUT=$< OUTPUT=$@ \
      MAX_RECORDS_IN_RAM=2500000 METRICS_FILE=metrics.$(SAMPLE) TMP_DIR=$(TMP) $(T)

    input_test.bam:
      $(F) samtools view -h $(TEST_BAM) | head -$(LINES_TEST) | samtools view -hbS - > $@ $(T)

    clean:
      rm -f *.sai *.sam *.bam *.fastq metrics* one* two* *.dump *.dot *.png *.e* *.o*

    .PHONY: clean all

  If you are familiar with make, this should be very straight forward. If not,
  do not worry check any of the makefile introductions out there.

  The important parts of this makefike are the P and S variables. As you can see
  every recipe is has the prefix P and the suffix S. That allows mih to build
  the graph when we execute the makefile.

  The prefix is just a call to mih. The suffix has some classic information
  related the execution of that recipe.

  If we execute the makefile, a dot file should be created in our working
  directory. That's a representation of our graph. You should see some files
  named with weird names. More on that later.

  We can visualize that graph:

  [![graph](http://is04607.com/mih/mih-image1.png)](http://is04607.com/mih/mih-image1.png)

  If everything went fine we should be ready to execute the instance of our
  pipeline. We do that by running mih's hpc and selecting a target scheduler.
  As I mention before, currently we are only supporting PBS. But writing any
  code for any other scheduler is fairly trivial. You can run:

    $ mih hpc pbs

  Mih will dump to the stdin the script that we would have to execute in order
  to schedule our jobs. To actually schedule the jobs we can:

    $ mih hpc pbs | bash

## Installing it

  Mih is coded in [Ruby](http://www.ruby-lang.org/en/) and only depends on [RGL](http://rgl.rubyforge.org/rgl/index.html),
  a library to work with graphs. The installation should be pretty straight
  forward:

    $ gem install rgl
    $ cd $WHATEVER
    $ git clone git@github.com:drio/makeItHappen.git
    $ # Asumming bash here:
    $ export PATH=$PATH:$WHATEVER/makeItHappen/bin
    $ mih
    Program    : mih (makeItHappen)
    Description: Generic distributed make for HPC environments
    Version    : 0.0.1a

    Usage      : mih <command> [options]

    Command    : builder    Generate a Graph adding the new command
                 hpc        Create a script for the targeted HPC scheduler


## Final remarks

  Mih is just a weekend project, but I hope you like it and decide to use it
  and improve it. All type of Feedback is very welcome.

  There quite a few things that I'd like to improve. The most important one is
  removing the need of marshalling all the jobs objects to disk.  I had to do
  that because I was having issues parsing them with
  [RGL](http://rgl.rubyforge.org/rgl/index.html). I am sure there has to be
  a better way so the job objects can be included within the file that represents
  the DG. Feel free to look around.

  There are some other things. But I hope we can work on them all together.
