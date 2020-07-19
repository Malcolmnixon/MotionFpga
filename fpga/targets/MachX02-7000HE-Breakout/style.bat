@ECHO OFF

REM Run VSG to check the files for VHDL style rules
vsg -c ../../style_rules.yaml style_files.yaml -of syntastic > style.log
