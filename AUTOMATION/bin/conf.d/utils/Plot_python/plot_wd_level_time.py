#!/usr/bin/python3
from __future__ import print_function

import sys,traceback
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
        if len(hfields) != 7:
            print("!!!ERROR: wrong header")
            sys.exit(2)
        filefd.close()
        self.deltat=float(hfields[0])/3600.
        self.starttime=float(hfields[1])/3600.
        self.endtime=float(hfields[2])/3600.

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
        data=np.loadtxt(files[0],skiprows=3)
        self.rows,self.cols=data.shape
        nfiles=len(files)
        data_all=np.zeros((self.rows,self.cols,nfiles),float)
        for i,dfile in enumerate(files):
            data_all[:,:,i]=np.loadtxt(dfile,skiprows=3)
        self.time=data_all[:,0,0]/3600.
        self.wind=data_all[:,1,:]
        self.wind_sd=data_all[:,2,:]
        #getting the angle is tricky because we want to wrap the values in order to be a continuous plot without jumps
        tempwd=data_all[:,3,:]
        #the final variable will be in self.wd. We start from the ground level
        self.wd=np.zeros((self.rows,nfiles),float)
        self.wd[0,:]=tempwd[0,:]
        self.wd_sd=data_all[:,4,:]
        #Going up in levels we add an offset of +-360 in order to guarantee the continuity of the vertical plot. Rescaling by 2pi doens't change the angle of course so it's safe
        for j in range(nfiles):
            offsetangle=0.
            for i in range(1,self.rows):
                self.wd[i,j]=tempwd[i,j]+offsetangle
                difference=self.wd[i-1,j]-self.wd[i,j]
                if (difference >= 180.):
                    offsetangle=offsetangle+360.
                    self.wd[i,j]=tempwd[i,j]+offsetangle
                if (difference <= -180.):
                    offsetangle=offsetangle-360.
                    self.wd[i,j]=tempwd[i,j]+offsetangle
        self.maxarraywd=np.zeros(nfiles,float)
        self.minarraywd=np.zeros(nfiles,float)
        #This last step is to rescale again the angle by a multiple of 2pi in order to have ranges in -180/+180 as a mean (north=0)
        for i in range(nfiles):
            self.maxarraywd[i]=np.max(self.wd[:,i])
            self.minarraywd[i]=np.min(self.wd[:,i])
            #get the mean value
            meanwd=(self.maxarraywd[i]+self.minarraywd[i])/2.
            #then get how many multiple of 360 we can remove
            meanfix=int(meanwd/360.)
            #Fix it
            if (meanfix > 0 ):
                self.wd[:,i]=self.wd[:,i]-360.*meanfix
            self.maxarraywd[i]=np.max(self.wd[:,i])
            self.minarraywd[i]=np.min(self.wd[:,i])

def main():
    files=sys.argv[1:4]
    nfiles=len(files)    
    data=Datastore(files)
    UTOFFSET=int(sys.argv[4])
    YEARF=str(sys.argv[5])
    MONTHF=str(sys.argv[6])
    DAYF=str(sys.argv[7])
    stringadata_fig=str(YEARF).strip()+'/'+str(MONTHF).strip()+'/'+str(DAYF).strip()

    hd=Header(files[0],UTOFFSET)

    #Dawn. dusk, sunset and sunrise
    HOURDAWN=int(sys.argv[8])
    HOURDUSK=int(sys.argv[9])
    HOURSUNSET=int(sys.argv[10])
    HOURSUNRISE=int(sys.argv[11])

    HOUR_SHIFT_PLOT=int(sys.argv[12])

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
            
    #Select arrays for printing (later at the end of program)
    printtime=data.time[start_index:end_index+1]
    printwind=data.wind[start_index:end_index+1,:]
    printwind_sd=data.wind_sd[start_index:end_index+1,:]
    printwd=data.wd[start_index:end_index+1,:]
    printwd_sd=data.wd_sd[start_index:end_index+1,:]

    for i in range(nfiles):
        regex = re.compile('_k..stat')
        stringext=re.findall(regex,files[i])
        level=stringext[0][2]
        #Base settings
        my_dpi=300
        font_size=9

        #Load header
        hd=Header(files[i],UTOFFSET)
        #Set limits
        maxval=np.max(data.wind[start_index:end_index]+data.wind_sd[start_index:end_index])
        minval=np.min(data.wind[start_index:end_index]-data.wind_sd[start_index:end_index])
        maxval_wd=np.max(data.wd[start_index:end_index]+data.wd_sd[start_index:end_index])
        minval_wd=np.min(data.wd[start_index:end_index]-data.wd_sd[start_index:end_index])
        maxval=maxval+maxval/10.
        minval=minval-minval/10.
        maxval_wd=maxval_wd+maxval_wd/10.
        minval_wd=minval_wd-minval_wd/10.
        minval=np.max([minval,0.])        

        #Set angle limits
        angle_values=np.zeros(abs(int(maxval_wd)-int(minval_wd)+1),float)
        taglia=len(angle_values)
        stepping=30.
        if ( taglia <= stepping*3):
            stepping=stepping/2.
        if ( taglia <= stepping*3):
            stepping=stepping/3.
        if ( taglia <= stepping*3):
            stepping=stepping/5.

        #Rounded margins:
        margin_left=int(round(int(minval_wd)/stepping)*stepping)
        if (margin_left > int(minval_wd)):
            margin_left=margin_left - stepping
        margin_right=int(round(int(maxval_wd)/stepping)*stepping)
        if (margin_right < int(maxval_wd)):
            margin_right=margin_right + stepping
        
        angle_values=np.arange(margin_left,margin_right+1,stepping)
        angle_names=angle_values.astype(int)
        for j in range(len(angle_values)):
            while (angle_names[j] < 0):
                angle_names[j]=angle_names[j]+360
        angle_names=angle_names

        #Plot wind direction
        title_label='Wind direction - Temporal evolution on level k='+level.strip()
        plt.figure(figsize=(1742./my_dpi, 1282./my_dpi), dpi=my_dpi)
        ax1 = plt.subplot(1,1,1)
        plt.rcParams['axes.labelsize'] = font_size
        plt.rcParams['xtick.labelsize'] = font_size
        plt.rcParams['ytick.labelsize'] = font_size
        plt.errorbar(data.time,data.wd[:,i], yerr=data.wd_sd[:,i],color='k',linewidth=2, ecolor='#878b91',elinewidth=0.5,capsize=2)
        plt.yticks(angle_values,angle_names)
        plt.axvline(x=hourdawn, linewidth=1, color='r', linestyle=':')
        plt.axvline(x=hourdusk, linewidth=1, color='r', linestyle=':')
        centery=(minval_wd+maxval_wd)/2.
        plt.text(hourdawn, centery, 'dawn', fontsize=font_size+1, color='r',horizontalalignment='center',verticalalignment='center')
        plt.text(hourdusk, centery, 'dusk', fontsize=font_size+1, color='r',horizontalalignment='center',verticalalignment='center')
#        plt.axes().set_aspect(0.36)
        plt.tick_params(which='both')
        plt.tick_params(which='major', length=7)
        plt.tick_params(which='minor', length=4)
        plt.minorticks_on()
        plt.title(title_label,fontsize=font_size+1.4, y=1.15)
        plt.xlabel('Hour (UT)',fontsize=font_size+1)
        plt.ylabel('Wind direction (deg)',fontsize=font_size+1)
        ax = plt.gca()
        plt.text(0, 1.13,stringadata_fig,verticalalignment='center',transform = ax.transAxes, fontsize=font_size+1)
        start, end = ax1.get_xlim()
        ax1.tick_params(labelsize=font_size+2)
        ax1.xaxis.set_ticks(np.arange(int(start), int(end), 1,dtype=int))
        plt.ylim(minval_wd,maxval_wd)
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
        ax2.set_xlabel('Hour (MST)',fontsize=font_size+2)
        ax2.tick_params(which='both')
        ax2.tick_params(which='major', length=7)
        ax2.tick_params(which='minor', length=4)
        ax2.minorticks_on()

        plt.tight_layout()
#        plt.subplots_adjust(left=0.11, right=0.98, top=0.84, bottom=0.11) 
 
        fileout="DATE_winddir_k"+level.strip()+"_evol_time.png"
        plt.savefig(fileout,dpi=my_dpi)
        print("Creato file con plot:", fileout)

        #Write out dat file
        fname="DATE_winddir_k"+level.strip()+"_evol_time.dat"
        f = open(fname, 'w')
        f.write('### WIND DIRECTION LEVEL K='+level.strip()+' TIME EVOLUTION'+'\n')
        f.write('### TIME(h) WD(deg) SIGMA_WD(deg)'+'\n')
        printdata=np.zeros((1,3),float)
        for j in range(len(printtime)):
            printdata[0,0]=printtime[j]
            printdata[0,1]=printwd[j,i]
            printdata[0,2]=printwd_sd[j,i]
            np.savetxt(f,printdata,fmt='%E',delimiter='\t')
        f.close()

if __name__ == '__main__':
    try:
        main()
    except:
        print("!!!Error: error plotting plot_wind_pv_level_time.py with input parameters: ",sys.argv)
        print(traceback.format_exc())
        sys.exit(1)


