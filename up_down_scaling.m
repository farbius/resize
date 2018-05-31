%% up/down scaling algorithm
% A Rostov 24/05/2018
% a.rostov@riftek.com
%%
clc
clear 
% fileID = -1;
% errmsg = '';
% while fileID < 0 
%    disp(errmsg);
%    filename = input('Open file: ', 's');
%    [fileID,errmsg] = fopen(filename);
%    I = imread(filename);
% end

I = imread('picture_2v.jpg');
[Nx, Ny, Nz] = size(I);

sign         = 1;
d_scaling    = 2;

up_scaling   = d_scaling;
down_scaling = d_scaling;

display('Writing data for RTL model...');
fidR = fopen('Rdata.txt', 'w');
fidG = fopen('Gdata.txt', 'w');
fidB = fopen('Bdata.txt', 'w');

zerI = zeros(Nx, Ny, Nz);

Iwr = cat(1, I, zerI, zerI);

for i = 1 : 3*Nx
    for j = 1 : Ny
      fprintf(fidR, '%x\n', Iwr(i, j, 1));
      fprintf(fidG, '%x\n', Iwr(i, j, 2));
      fprintf(fidB, '%x\n', Iwr(i, j, 3));
    end
end
fclose(fidR);
fclose(fidG);
fclose(fidB);




%%
fid = fopen('parameters.vh', 'w');
fprintf(fid,'parameter N_y          = %d ;\n', Ny);
fprintf(fid,'parameter N_x          = %d ;\n', Nx);
fprintf(fid,'parameter d_scaling    = %d ;\n', d_scaling);
fprintf(fid,'parameter sign         = %d ;\n', sign);
fclose(fid);




% fltr = [1 1 1; 1 1 1; 1 1 1];

% fltr = floor(ones(f_size).*1);
% fltr = floor(magic(f_size)./4);
% 
% fid = fopen('Filter_Coe.txt', 'w');
% for i = 1 : f_size
%     for j = 1 : f_size
%             fprintf(fid, '%x\n', fltr(i,j));
%     end
% end
% fclose(fid);

x_us = ceil(Nx*up_scaling)
y_us = ceil(Ny*up_scaling)

I_data = double(I);
I_filter = zeros(x_us, y_us, Nz);
%%
k  = 1;
l  = 1;
for i = 1 : x_us
    
   if(mod(i - 1, up_scaling) == 0)
            
         for j = 1 : y_us 
                if(mod(j - 1, up_scaling) == 0)
               I_filter(i, j, 1) = I_data(k, l, 1); 
               I_filter(i, j, 2) = I_data(k, l, 2); 
               I_filter(i, j, 3) = I_data(k, l, 3);
               l = l + 1;
                end                
         end          
          k = k + 1;      
    end
          l = 1;   
end

I_filter = double(I_filter);

%% up resize
I_neigbor = zeros(x_us, y_us, Nz);

for i = 1 : x_us
     if(mod(i - 1, up_scaling) == 0)        
         for j = 1 : y_us
                if(mod(j - 1, up_scaling) == 0)
                 I_neigbor(i, j, 1) = I_filter(i, j, 1); 
                 I_neigbor(i, j, 2) = I_filter(i, j, 2); 
                 I_neigbor(i, j, 3) = I_filter(i, j, 3);                
                else
                 I_neigbor(i, j, 1) = I_neigbor(i, j - 1, 1); 
                 I_neigbor(i, j, 2) = I_neigbor(i, j - 1, 2); 
                 I_neigbor(i, j, 3) = I_neigbor(i, j - 1, 3);        
                end
         end  % j       
     else
         for j = 1 : y_us
                if(mod(j - 1, up_scaling) == 0)
                 I_neigbor(i, j, 1) = I_neigbor(i - 1, j - 0, 1); 
                 I_neigbor(i, j, 2) = I_neigbor(i - 1, j - 0, 2); 
                 I_neigbor(i, j, 3) = I_neigbor(i - 1, j - 0, 3);   
                else
                 I_neigbor(i, j, 1) = I_neigbor(i - 1, j - 1, 1); 
                 I_neigbor(i, j, 2) = I_neigbor(i - 1, j - 1, 2); 
                 I_neigbor(i, j, 3) = I_neigbor(i - 1, j - 1, 3);
                end
         end
     end
end
I_neigbor = uint8(I_neigbor);

rOld = uint8(I_neigbor(:, :, 1));

%% down resize

x_ds = ceil(Nx/down_scaling)
y_ds = ceil(Ny/down_scaling)
% 
I_decimate = zeros(x_ds, y_ds, Nz);
for i = 1 : x_ds
    for j = 1 : y_ds 
                 I_decimate(i, j, 1) = I_data(1 + (i - 1)*down_scaling, 1  + (j - 1)*down_scaling, 1); 
                 I_decimate(i, j, 2) = I_data(1 + (i - 1)*down_scaling, 1  + (j - 1)*down_scaling, 2); 
                 I_decimate(i, j, 3) = I_data(1 + (i - 1)*down_scaling, 1  + (j - 1)*down_scaling, 3);

    end 
end
I_decimate = uint8(I_decimate);
% display('Please, start write_prj.tcl');
% prompt = 'Press Enter when RTL modeling is done \n';
% x = input(prompt);
% 
% % read processing data
fidR = fopen(fullfile([pwd '\decimate_picture.sim\sim_1\behav\xsim'],'Rs_out.txt'), 'r');
fidG = fopen(fullfile([pwd '\decimate_picture.sim\sim_1\behav\xsim'],'Gs_out.txt'), 'r');
fidB = fopen(fullfile([pwd '\decimate_picture.sim\sim_1\behav\xsim'],'Bs_out.txt'), 'r');
R = zeros(1, Nx*Ny);
G = zeros(1, Nx*Ny);
B = zeros(1, Nx*Ny);
  R = fscanf(fidR,'%d');  
  G = fscanf(fidG,'%d');  
  B = fscanf(fidB,'%d');  
fclose(fidR);
fclose(fidG);
fclose(fidB);


if sign == 0

Idw_process = zeros(x_ds, y_ds, 3);
n = 1;
for i = 1 : x_ds 
    for j = 1 : y_ds 
       Idw_process(i, j, 1) = R(n); 
       Idw_process(i, j, 2) = G(n); 
       Idw_process(i, j, 3) = B(n); 
       n = n + 1;
    end
end
Idw_process = uint8(Idw_process);

else
% 
% 

Iup_process = zeros(x_us, y_us, Nz);
n = 1;
for i = 1 : x_us
    for j = 1 : y_us 
       Iup_process(i, j, 1) = R(n); 
       Iup_process(i, j, 2) = G(n); 
       Iup_process(i, j, 3) = B(n); 
       n = n + 1;
    end
end
Iup_process = uint8(Iup_process);
rNew = uint8(Iup_process(:, :, 1));

end

figure(1)
imshow(I)
title('исходное изображение')
grid on





if (sign == 0)
    
figure(3)
imshow(Idw_process)
title('after processing HDL')
grid on

figure(2)
imshow(I_decimate)
title('down resize')
grid on

else
    
    % 
figure(2)
imshow(uint8(I_filter))
title('RAW resized picture')
grid on

figure(4)
imshow(I_neigbor)
title('up resize')
grid on

figure(5)
imshow(Iup_process)
title('after processing HDL')
grid on
end
% 
