%% 
% Description: 
% A example to calculate canopy photosynthesis based on point clouds.
% Author: Fusang Liu
% Date: 2021-10-21 

%% Display maize point clouds
pc=pcread('example_maize_pc.ply');
pcshow(pc)

%% Meshing 
cmd=['C:\Users\liufusang\Desktop\training\PCSR.exe "C:\Users\liufusang\Desktop\training" "example_maize_pc.ply" "C:\Users\liufusang\Desktop\training" "example_maize_pm.ply"']; 
system(cmd)
[group_sp,group_se]=read_ply('example_maize_pm.ply');

%% Create virtual canopy 
row_num=4; plant_num=4;
plant_dis=0.2; row_dis=0.5;
[group_rp,group_re]=plant2canopy(group_se,group_sp,row_num,plant_num,plant_dis,row_dis);
figure
trisurf(group_re,group_rp(:,1),group_rp(:,2),group_rp(:,3),'Facecolor',[0.133,0.545,0.133],'FaceAlpha', 0.5,'EdgeColor','none')
axis on
axis equal

canopy_facet_num=length(group_re);
input_mat=[ones(canopy_facet_num,1),ones(canopy_facet_num,1),ones(canopy_facet_num,1),zeros(canopy_facet_num,1),...
    zeros(canopy_facet_num,1),group_rp(group_re(:,1),:).*100,group_rp(group_re(:,2),:).*100,group_rp(group_re(:,3),:).*100,...
    zeros(canopy_facet_num,1),ones(canopy_facet_num,1).*0.05,ones(canopy_facet_num,1).*0.05];
writematrix(input_mat,'canopy_model.txt','Delimiter',' ');

%%  Ray tracing 
cmd=['C:\Users\liufusang\Desktop\training\fastTracerV1.22.exe -D 30 70 75 175 0 300 -L 31 -S 12 -A 0.7 -d 120 -W 13 1 13 -n 0.1 -m ','C:\Users\liufusang\Desktop\training\canopy_model.txt',' -o ','C:\Users\liufusang\Desktop\training\result.txt',' -z 0.5']; 
system(cmd);

%% A-Q curve fiting
A=[31.49 30.83 29.15 27.48 25.30 21.86 16.25 12.64 8.68 6.52 4.20 1.56 -2.81];
PPFD=[2000 1600 1200 1000 800 600 400 300 200 150 100 50 0];
para0=[0.1 30 1 0.5];  % initial parameters
[para_fit,resnorm]= lsqcurvefit(@A_Q_curve,para0,PPFD,A,[0 0 0 0], [+inf +inf +inf 1]);
PPFD_m=0:1:2500;
for i=1:length(PPFD_m)
A_m(i) =A_Q_curve(para_fit,PPFD_m(i));
end

figure
plot(PPFD,A,'*')
hold on
plot (PPFD_m, A_m,'-')

%% canopy light interception and photosynthetic rate
result=readmatrix('C:\Users\liufusang\Desktop\training\result.txt');
pos=result(:,6:14);
pos_all=[pos(:,1:3);pos(:,4:6);pos(:,7:9)];
faces=[(1:length(pos))',(length(pos)+1:length(pos)*2)',(length(pos)*2+1:length(pos)*3)'];
facet_area=result(:,18)/10000;
for i=1:12
PPFD_c(:,i)=result(:,25+i*7);
end

figure
trisurf(faces,pos_all(:,1),pos_all(:,2),pos_all(:,3),PPFD_c(:,7),'FaceAlpha',0.9,'EdgeColor','none'),caxis([0 2000])
set(gcf,'Color',[1,1,1])
axis equal
colorbar

for i=1:length(PPFD_c(:,7))
A_mc(i) =A_Q_curve(para_fit,PPFD_c(i,7));
end

figure
trisurf(faces,pos_all(:,1),pos_all(:,2),pos_all(:,3),A_mc,'FaceAlpha', 0.9,'EdgeColor','none')
set(gcf,'Color',[1,1,1])
axis equal
colorbar

A_hour=sum(A_mc'.*facet_area); % Total canopy photosynthetic rate

