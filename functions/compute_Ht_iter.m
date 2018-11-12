function [Htres,dts,offset2,Ht_inliers,corresp,emin_Ht,step,info] = compute_Ht_iter(tracks,fps1,fps2,offset1,offset2,thr,rounds_ransac,rounds_iter,kmax,kmin,verbose_fn,gui_update_fn)
emin_Ht = [];
Htres = [];
Ht_inliers = [];

verbose = 0;
if(nargin>10)
   verbose = 1; 
end
if(nargin>11)
   update_gui = 1; 
end
scale = kmin;
step(1) = 2^kmin;
prev_inliers = 0;
skipped = 0;
r = 1;
info.result = 'did_not_converge';
for k = 1:rounds_iter
    corresp = generate_corresp(tracks,fps1,fps2,offset1,offset2);
    u1 = a2h(corresp{1});
    u2 = a2h(corresp{2});
    if(verbose)
        verbose_fn( sprintf('using d = %d frames (%f seconds)',step(r),step(r)/fps2));
    end
    pause(0.1);
    [Htres1,dt1,inliers1,emin_Ht] = ransac_Ht(u1,u2,step(r),thr,rounds_ransac);
    [Htres2,dt2,inliers2,emin_Ht] = ransac_Ht(u1,u2,-step(r),thr,rounds_ransac);
    if(length(inliers1)>length(inliers2))
        dt = dt1;
        Htres = Htres1;
        inliers = inliers1;
        step(r)= step(r);
    else
        dt = dt2;
        Htres = Htres2;
        inliers = inliers2;
        step(r) = -step(r);
    end
    if(verbose)
        verbose_fn(sprintf('found %d inliers with beta=%f',length(inliers),step(r)/fps2*dt));
    end
    dts(r) = dt;
    Ht_inliers{r} = inliers;
    %inlier_ratio = length(inliers)/size(corresp,2);
    if(skipped>kmax)
        info.result = 'skipped more than kmax times';
        inlier_ratio = prev_inliers/size(corresp,2);
        break;
    end
    if(prev_inliers>=length(inliers)&&scale<kmax)
        scale=scale+1; 
        step(r) = 2^scale;
        skipped = skipped +1;
        continue;
    end
    if(scale>=0&&prev_inliers>=length(inliers))
        scale = 0;
        step(r) = 2^scale;
        skipped = skipped +1;
        continue;
    end
    
    prev_inliers = length(inliers);
    step(r+1) = 2^scale;
    offset2 = offset2-step(r)/fps2*dts(r);
    skipped = 0;
    r = r+1;
    if(verbose)
        verbose_fn(sprintf('STEP ACCEPTED - current offset2 = %f',offset2));
    end
    if(update_gui)
       gui_update_fn(offset2); 
    end
    pause(0.01);
end
info.iterations = k;
info.iterations_accepted = r;