prj_project open "MotionFpga.ldf"
prj_run Synthesis -impl impl1 -task Lattice_Synthesis -forceOne
prj_run Map -impl impl1 -task MapTrace -forceOne
prj_run PAR -impl impl1 -task PARTrace -forceOne 
prj_run PAR -impl impl1 -task IOTiming -forceOne
prj_run Export -impl impl1 -task Jedecgen -forceOne
prj_project close