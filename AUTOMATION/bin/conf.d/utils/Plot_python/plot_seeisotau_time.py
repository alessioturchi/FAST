#!/usr/bin/python3
from __future__ import print_function

import sys,os,traceback
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
import re

class Header(object):
    def __init__(self, dfile, utoffset) :
        self.dfile=dfile
        self.utoffset=utoffset
        filefd = open(dfile)
        filefd.readline()
        self.linefile=filefd.readline()
        hfields = self.linefile.split()
        if len(hfields) < 13:
            print("!!!ERROR: wrong header")
            sys.exit(2)
        filefd.close()
        self.deltat=float(hfields[0])/60.
        self.starttime=float(hfields[1])/60.
        self.endtime=float(hfields[2])/60.
        self.startheight=int(hfields[5])
        self.endheight=int(hfields[6])

        self.starthour=int(self.starttime)
        self.startminute=int((self.starttime-self.starthour)*60.)
        self.endhour=int(self.endtime)
        self.endminute=int((self.endtime-self.endhour)*60.)
    
        self.starthourlt=int(self.starthour+utoffset)
        if self.starthourlt < 0 :
            self.starthourlt += 24
        if self.starthourlt > 24 :
            self.starthourlt -= 24
        self.endhourlt=int(self.endhour+utoffset)
        if self.endhourlt < 0 :
            self.endhourlt += 24
        if self.endhourlt > 24 :
            self.endhourlt -= 24

        self.stringaora=str(self.starthour).strip()+":"
        if (self.startminute <= 9):
            self.stringaora=self.stringaora+'0'+str(self.startminute).strip()
        if (self.startminute >= 10):
            self.stringaora=self.stringaora+str(self.startminute).strip()
        self.stringaora=self.stringaora+'-'+str(self.endhour).strip()+":"
        if (self.endminute <= 9):
            self.stringaora=self.stringaora+'0'+str(self.endminute).strip()
        if (self.endminute >= 10):
            self.stringaora=self.stringaora+str(self.endminute).strip()

        self.stringaoralt=str(self.starthourlt).strip()+":"
        if (self.startminute <= 9):
            self.stringaoralt=self.stringaoralt+'0'+str(self.startminute).strip()
        if (self.startminute >= 10):
            self.stringaoralt=self.stringaoralt+str(self.startminute).strip()
        self.stringaoralt=self.stringaoralt+'-'+str(self.endhourlt).strip()+":"
        if (self.endminute <= 9):
            self.stringaoralt=self.stringaoralt+'0'+str(self.endminute).strip()
        if (self.endminute >= 10):
            self.stringaoralt=self.stringaoralt+str(self.endminute).strip()

    def __str__(self):
        return '%s: %f %f %f %f %f %f %f \n %s'%(self.dfile, self.utoffset,self.deltat, self.starttime, self.endtime, self.endtime, self.linefile, self.stringaora, self.stringaoralt)

class Datastore(object):
    def __init__(self,files) :
        data=np.loadtxt(files,skiprows=3)
        self.rows,self.cols=data.shape
        data_all=np.zeros((self.rows,self.cols),float)
        data_all[:,:]=np.loadtxt(files,skiprows=3)
        self.time=data_all[:,0]/60.
        self.see=data_all[:,1]
        self.see_sd=data_all[:,2]
        self.iso=data_all[:,5]
        self.iso_sd=data_all[:,6]
        if (self.cols == 9):
            self.tau=data_all[:,7]
            self.tau_sd=data_all[:,8]
            self.flagtau=1
        else:
            self.flagtau=0

def main():
    files=sys.argv[1]
    nfiles=len(files)    
    data=Datastore(files)
    UTOFFSET=int(sys.argv[2])
    YEARF=str(sys.argv[3])
    MONTHF=str(sys.argv[4])
    DAYF=str(sys.argv[5])
    stringadata_fig=str(YEARF).strip()+'/'+str(MONTHF).strip()+'/'+str(DAYF).strip()

    hd=Header(files,UTOFFSET)

    #Dawn. dusk, sunset and sunrise
    HOURDAWN=int(sys.argv[6])
    HOURDUSK=int(sys.argv[7])
    HOURSUNSET=int(sys.argv[8])
    HOURSUNRISE=int(sys.argv[9])

    typeplot=str(sys.argv[10]).strip()

    HOUR_SHIFT_PLOT=int(sys.argv[11])

    #Start compute time scales
    hourdawn=float(HOURDAWN)/60.
    hourdusk=float(HOURDUSK)/60.
    hoursunset=float(HOURSUNSET)/60.
    hoursunrise=float(HOURSUNRISE)/60.

    stringadata_fig=str(YEARF).strip()+'/'+str(MONTHF).strip()+'/'+str(DAYF).strip()
    #End compute time scales

    #Get indices of start and stop
    start_index=0
    end_index=len(data.time)-1
    for i in range(len(data.time)):
        if (data.time[i] <= hd.starttime):
            start_index=i
        if (data.time[i] <= hd.endtime):
            end_index=i
            
    #Base settings
    my_dpi=300
    font_size=9

    #Load header
    hd=Header(files,UTOFFSET)
    #Set limits
    maxval_see=np.max(data.see[start_index:end_index]+data.see_sd[start_index:end_index])
    minval_see=np.min(data.see[start_index:end_index]-data.see_sd[start_index:end_index])
    maxval_see=maxval_see+maxval_see/30.
    minval_see=minval_see-minval_see/30.
    minval_see=np.max([minval_see,0.])
    maxval_iso=np.max(data.iso[start_index:end_index]+data.iso_sd[start_index:end_index])
    minval_iso=np.min(data.iso[start_index:end_index]-data.iso_sd[start_index:end_index])
    maxval_iso=maxval_iso+maxval_iso/30.
    minval_iso=minval_iso-minval_iso/30.
    minval_iso=np.max([minval_iso,0.])

    if (data.flagtau == 1):
        maxval_tau=np.max(data.tau[start_index:end_index]+data.tau_sd[start_index:end_index])
        minval_tau=np.min(data.tau[start_index:end_index]-data.tau_sd[start_index:end_index])
        maxval_tau=maxval_tau+maxval_tau/30.
        minval_tau=minval_tau-minval_tau/30.
        minval_tau=np.max([minval_tau,0.])


    stringah=str(hd.startheight).strip()+'_'+str(hd.endheight).strip()
    if (os.path.basename(files).split('_')[1] == 'OS18'):
        stringah=stringah+'_OS18'
    #WORKAROUND TO WRITE "DOME" ON THE LOWEST HEIGHT
    #I SUPPOSE THAT WE DON'T HAVE A BOUNDARY LAYER LOWER THAT 200 AND A TELESCOPE TALLER THAN THE BOUNDARY LAYER.... ;-)
    if (hd.startheight < 200):
        stringahtitle='integrated in [dome-'+str(hd.endheight).strip()+']m'
    else:
        stringahtitle='integrated in ['+str(hd.startheight).strip()+'-'+str(hd.endheight).strip()+']m'

    #Select arrays for printing (later at the end of program)
    printtime=data.time[start_index:end_index+1]
    printsee=data.see[start_index:end_index+1]
    printsee_sd=data.see_sd[start_index:end_index+1]
    printiso=data.iso[start_index:end_index+1]
    printiso_sd=data.iso_sd[start_index:end_index+1]
    if (data.flagtau == 1):   
        printtau=data.tau[start_index:end_index+1]
        printtau_sd=data.tau_sd[start_index:end_index+1]


    #Plot see
    title_label='$\epsilon_{'+typeplot+'}$ - Temporal evolution - '+stringahtitle.strip()
    plt.figure(figsize=(1742./my_dpi, 1282./my_dpi), dpi=my_dpi)
    ax1 = plt.subplot(1,1,1)
    plt.rcParams.update({'mathtext.default':  'regular' })        
    plt.rcParams['axes.labelsize'] = font_size
    plt.rcParams['xtick.labelsize'] = font_size
    plt.rcParams['ytick.labelsize'] = font_size
    plt.errorbar(data.time,data.see[:], yerr=data.see_sd[:],color='k',linewidth=2, ecolor='#878b91',elinewidth=0.5,capsize=2)
    plt.axvline(x=hourdawn, linewidth=1, color='r', linestyle=':')
    plt.axvline(x=hourdusk, linewidth=1, color='r', linestyle=':')
    centery=(minval_see+maxval_see)/2.
    plt.text(hourdawn, centery, 'dawn', fontsize=font_size+1, color='r',horizontalalignment='center',verticalalignment='center')
    plt.text(hourdusk, centery, 'dusk', fontsize=font_size+1, color='r',horizontalalignment='center',verticalalignment='center')
#    plt.axes().set_aspect(0.36)
    plt.tick_params(which='both')
    plt.tick_params(which='major', length=7)
    plt.tick_params(which='minor', length=4)
    plt.minorticks_on()
    plt.title(title_label,fontsize=font_size+1.4, y=1.15)
    plt.xlabel('Hour (UT)',fontsize=font_size+1)
    plt.ylabel('$\epsilon_{'+typeplot+'}$ (arcsec)',fontsize=font_size+2)
    ax = plt.gca()
    plt.text(0, 1.13,stringadata_fig,verticalalignment='center',transform = ax.transAxes, fontsize=font_size+1)
    start, end = ax1.get_xlim()
    ax1.tick_params(labelsize=font_size+2  )
    ax1.xaxis.set_ticks(np.arange(int(start), int(end), 1,dtype=int))
    plt.ylim(minval_see,maxval_see)
    plt.xlim(hoursunset,hoursunrise)
    ax2 = ax1.twiny()
    ax2.set_xlim(ax1.get_xlim())
    ax1Ticks = ax1.get_xticks()

    ax1Ticks_rescale=ax1Ticks.copy()
    if (HOUR_SHIFT_PLOT != 0):
        for idxtick in range(len(ax1Ticks_rescale)):
            ax1Ticks_rescale[idxtick]=ax1Ticks_rescale[idxtick]+HOUR_SHIFT_PLOT
            if (ax1Ticks_rescale[idxtick] < 0):
                ax1Ticks_rescale[idxtick]=ax1Ticks_rescale[idxtick]+24
            ax1Ticks_rescale[idxtick]=str(ax1Ticks_rescale[idxtick])
    ax1.set_xticklabels(ax1Ticks_rescale,fontsize=font_size+1)

    ax2.set_xticks(ax1Ticks)
    ax2Ticks=ax1Ticks+UTOFFSET+HOUR_SHIFT_PLOT
    for k in range(len(ax2Ticks)):
        if (ax2Ticks[k] < 0):
            ax2Ticks[k]= ax2Ticks[k]+24
    ax2.set_xbound(ax1.get_xbound())
    ax2.set_xticklabels(ax2Ticks,fontsize=font_size+1)
    ax2.set_xlabel('Hour (MST)',fontsize=font_size+1)
    ax2.tick_params(which='both')
    ax2.tick_params(which='major', length=7)
    ax2.tick_params(which='minor', length=4)
    ax2.minorticks_on()

    plt.tight_layout()
#    plt.subplots_adjust(left=0.11, right=0.98, top=0.84, bottom=0.11) 
 
    fileout="DATE_see_evol_time_Height_"+stringah+'.png'
    plt.savefig(fileout,dpi=my_dpi)
    print("Creato file con plot:", fileout)

    #Write out dat file
    fname="DATE_see_evol_time_Height_"+stringah+'.dat'
    f = open(fname, 'w')
    f.write('### SEEING TIME EVOLUTION INTEGRATED IN '+stringah+' meters'+'\n')
    f.write('### TIME(h) SEEING(arcsec) SIGMA_SEEING(arcsec)'+'\n')
    printdata=np.zeros((1,3),float)
    for j in range(len(printtime)):
        printdata[0,0]=printtime[j]
        printdata[0,1]=printsee[j]
        printdata[0,2]=printsee_sd[j]
        np.savetxt(f,printdata,fmt='%E',delimiter='\t')
    f.close()

    #Plot iso
    title_label='$\\theta_{0,'+typeplot+'}$ - Temporal evolution - '+stringahtitle.strip()
    plt.figure(figsize=(1742./my_dpi, 1282./my_dpi), dpi=my_dpi)
    ax1 = plt.subplot(1,1,1)
    plt.rcParams.update({'mathtext.default':  'regular' })        
    plt.rcParams['axes.labelsize'] = font_size
    plt.rcParams['xtick.labelsize'] = font_size
    plt.rcParams['ytick.labelsize'] = font_size
    plt.errorbar(data.time,data.iso[:], yerr=data.iso_sd[:],color='k',linewidth=2, ecolor='#878b91',elinewidth=0.5,capsize=2)
    plt.axvline(x=hourdawn, linewidth=1, color='r', linestyle=':')
    plt.axvline(x=hourdusk, linewidth=1, color='r', linestyle=':')
    centery=(minval_iso+maxval_iso)/2.
    plt.text(hourdawn, centery, 'dawn', fontsize=font_size+1, color='r',horizontalalignment='center',verticalalignment='center')
    plt.text(hourdusk, centery, 'dusk', fontsize=font_size+1, color='r',horizontalalignment='center',verticalalignment='center')
#    plt.axes().set_aspect(0.36)
    plt.tick_params(which='both')
    plt.tick_params(which='major', length=7)
    plt.tick_params(which='minor', length=4)
    plt.minorticks_on()
    plt.title(title_label,fontsize=font_size+1.4, y=1.15)
    plt.xlabel('Hour (UT)',fontsize=font_size+1)
    plt.ylabel('$\\theta_{0,'+typeplot+'}$ (arcsec)',fontsize=font_size+2)
    ax = plt.gca()
    plt.text(0, 1.13,stringadata_fig,verticalalignment='center',transform = ax.transAxes, fontsize=font_size+1)
    start, end = ax1.get_xlim()
    ax1.tick_params(labelsize=font_size+2  )
    ax1.xaxis.set_ticks(np.arange(int(start), int(end), 1,dtype=int))
    plt.ylim(minval_iso,maxval_iso)
    plt.xlim(hoursunset,hoursunrise)
    ax2 = ax1.twiny()
    ax2.set_xlim(ax1.get_xlim())
    ax1Ticks = ax1.get_xticks()

    ax1Ticks_rescale=ax1Ticks.copy()
    if (HOUR_SHIFT_PLOT != 0):
        for idxtick in range(len(ax1Ticks_rescale)):
            ax1Ticks_rescale[idxtick]=ax1Ticks_rescale[idxtick]+HOUR_SHIFT_PLOT
            if (ax1Ticks_rescale[idxtick] < 0):
                ax1Ticks_rescale[idxtick]=ax1Ticks_rescale[idxtick]+24
            ax1Ticks_rescale[idxtick]=str(ax1Ticks_rescale[idxtick])
    ax1.set_xticklabels(ax1Ticks_rescale,fontsize=font_size+1)

    ax2.set_xticks(ax1Ticks)
    ax2Ticks=ax1Ticks+UTOFFSET+HOUR_SHIFT_PLOT
    for k in range(len(ax2Ticks)):
        if (ax2Ticks[k] < 0):
            ax2Ticks[k]= ax2Ticks[k]+24
    ax2.set_xbound(ax1.get_xbound())
    ax2.set_xticklabels(ax2Ticks,fontsize=font_size+1)
    ax2.set_xlabel('Hour (MST)',fontsize=font_size+1)
    ax2.tick_params(which='both')
    ax2.tick_params(which='major', length=7)
    ax2.tick_params(which='minor', length=4)
    ax2.minorticks_on()

    plt.tight_layout()
#    plt.subplots_adjust(left=0.1, right=0.96, top=0.84, bottom=0.11) 
 
    fileout="DATE_iso_evol_time_Height_"+stringah+'.png'
    plt.savefig(fileout,dpi=my_dpi)
    print("Creato file con plot:", fileout)

    #Write out dat file
    fname="DATE_iso_evol_time_Height_"+stringah+'.dat'
    f = open(fname, 'w')
    f.write('### ISOPLATANTIC ANGLE TIME EVOLUTION INTEGRATED IN '+stringah+' meters'+'\n')
    f.write('### TIME(h) ISO(arcsec) SIGMA_ISO(arcsec)'+'\n')
    printdata=np.zeros((1,3),float)
    for j in range(len(printtime)):
        printdata[0,0]=printtime[j]
        printdata[0,1]=printiso[j]
        printdata[0,2]=printiso_sd[j]
        np.savetxt(f,printdata,fmt='%E',delimiter='\t')
    f.close()

    if (data.flagtau==1):
            #Plot tau
        title_label='$\\tau_{0,'+typeplot+'}$ - Temporal evolution - '+stringahtitle.strip()
        plt.figure(figsize=(1742./my_dpi, 1282./my_dpi), dpi=my_dpi)
        ax1 = plt.subplot(1,1,1)
        plt.rcParams.update({'mathtext.default':  'regular' })        
        plt.rcParams['axes.labelsize'] = font_size
        plt.rcParams['xtick.labelsize'] = font_size
        plt.rcParams['ytick.labelsize'] = font_size
        plt.errorbar(data.time,data.tau[:], yerr=data.tau_sd[:],color='k',linewidth=2, ecolor='#878b91',elinewidth=0.5,capsize=2)
        plt.axvline(x=hourdawn, linewidth=1, color='r', linestyle=':')
        plt.axvline(x=hourdusk, linewidth=1, color='r', linestyle=':')
        centery=(minval_tau+maxval_tau)/2.
        plt.text(hourdawn, centery, 'dawn', fontsize=font_size+1, color='r',horizontalalignment='center',verticalalignment='center')
        plt.text(hourdusk, centery, 'dusk', fontsize=font_size+1, color='r',horizontalalignment='center',verticalalignment='center')
    #    plt.axes().set_aspect(0.36)
        plt.tick_params(which='both')
        plt.tick_params(which='major', length=7)
        plt.tick_params(which='minor', length=4)
        plt.minorticks_on()
        plt.title(title_label,fontsize=font_size+1.4, y=1.15)
        plt.xlabel('Hour (UT)',fontsize=font_size+1)
        plt.ylabel('$\\tau_{0,'+typeplot+'}$ (ms)',fontsize=font_size+2)
        ax = plt.gca()
        plt.text(0, 1.13,stringadata_fig,verticalalignment='center',transform = ax.transAxes, fontsize=font_size+1)
        start, end = ax1.get_xlim()
        ax1.tick_params(labelsize=font_size+2  )
        ax1.xaxis.set_ticks(np.arange(int(start), int(end), 1,dtype=int))
        plt.ylim(minval_tau,maxval_tau)
        plt.xlim(hoursunset,hoursunrise)
        ax2 = ax1.twiny()
        ax2.set_xlim(ax1.get_xlim())
        ax1Ticks = ax1.get_xticks()

        ax1Ticks_rescale=ax1Ticks.copy()
        if (HOUR_SHIFT_PLOT != 0):
            for idxtick in range(len(ax1Ticks_rescale)):
                ax1Ticks_rescale[idxtick]=ax1Ticks_rescale[idxtick]+HOUR_SHIFT_PLOT
                if (ax1Ticks_rescale[idxtick] < 0):
                    ax1Ticks_rescale[idxtick]=ax1Ticks_rescale[idxtick]+24
                ax1Ticks_rescale[idxtick]=str(ax1Ticks_rescale[idxtick])
        ax1.set_xticklabels(ax1Ticks_rescale,fontsize=font_size+1)

        ax2.set_xticks(ax1Ticks)
        ax2Ticks=ax1Ticks+UTOFFSET+HOUR_SHIFT_PLOT
        for k in range(len(ax2Ticks)):
            if (ax2Ticks[k] < 0):
                ax2Ticks[k]= ax2Ticks[k]+24
        ax2.set_xbound(ax1.get_xbound())
        ax2.set_xticklabels(ax2Ticks,fontsize=font_size+1)
        ax2.set_xlabel('Hour (MST)',fontsize=font_size+1)
        ax2.tick_params(which='both')
        ax2.tick_params(which='major', length=7)
        ax2.tick_params(which='minor', length=4)
        ax2.minorticks_on()
    
        plt.tight_layout()
#        plt.subplots_adjust(left=0.1, right=0.96, top=0.84, bottom=0.11) 
     
        fileout="DATE_tau_evol_time_Height_"+stringah+'.png'
        plt.savefig(fileout,dpi=my_dpi)
        print("Creato file con plot:", fileout)
    
        #Write out dat file
        fname="DATE_tau_evol_time_Height_"+stringah+'.dat'
        f = open(fname, 'w')
        print('### WAVEFRONT COHERENCE TI;E TIME EVOLUTION INTEGRATED IN '+stringah+' meters',file=f)
        f.write('### TIME(h) TAU(ms) SIGMA_TAU(ms)'+'\n')
        printdata=np.zeros((1,3),float)
        for j in range(len(printtime)):
            printdata[0,0]=printtime[j]
            printdata[0,1]=printtau[j]
            printdata[0,2]=printtau_sd[j]
            np.savetxt(f,printdata,fmt='%E',delimiter='\t')
        f.close()

if __name__ == '__main__':
    try:
        main()
    except:
        print("!!!Error: error plotting plot_seeisotau_time.py with input parameters: ",sys.argv)
        print(traceback.format_exc())
        sys.exit(1)


