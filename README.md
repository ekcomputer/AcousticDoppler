# *Riv2xls*

This is on branch one.
By Ethan Kyzivat and Ted Langhorst, with suggestions from Wayana Dolan  
August 2018  
Written on a moving boat in the Peace-Athabasca Delta.  

    A script to pull data and metadata from a RiverSurveyorLive Matlab
    export and write them to an excel file.  Prompts user input to select
    directory containing the .mat files exported from River Surveyor Live.
    It is necessary to export the day's files from RSL (ctrl + t, Matlab 
    export all).  If you set usesummfile equal to 1, then you must export 
    the summary file from
    RSL.  (ctrl + s), make sure all are highlighed red (default), and save
    as ascii.  The file name
    doesn't matter, but the extension must be .dis.  This script supports 
    multiple .dis input files if you are limited by RAM and have to export
    these files in multiple batches.
    Output QC file appears in this directory.

## *Requirements*
    Matlab 9.3 (R2017b) - may have slight incompatibilities with earlier 
    Matlab versions

## *Version History*
    Version 10 intelligently decides whethr or not to correct for the
    time firmware glitch, based on whether the actual date is August 12
    or earlier.  Also has an error message if number of lines in .dis
    file are different from number of .mat files

    Version 9 ensures that each line of the .dis files is matched to
    proper file name AND can parse more thabn one .dis files, so no
    manual splicing is needed!  Also fixes bug in end date (introduced in
    version 8).

    Version 8 corrects for firmware glitch that gives improper date.
    Also doesn't report mean veloc unless using the .dis file

    Version 7 saves lat/long, adds error message for improper loading.

    Version 6 fixes boat:water ratio inversion; only looks at HDOP and
    GPS_quality within transect, not at edges; stops auto-populating
    Track reference field (since these values are not in .mat file)
