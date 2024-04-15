
set gpunum = `nvidia-smi | grep -A1 "Tesla" | awk ' BEGIN{count=0} {if (count == 0) {gpunum = $2; count = count+1}else if(count == 1){util = $13; print gpunum " " util; count=count+1} else {count=0}}' | awk '{if ($2 == "0%"){print $1}}' | sort | head -1`
set gpucount = `nvidia-smi | grep -A1 "Tesla" | awk ' BEGIN{count=0} {if (count == 0) {gpunum = $2; count = count+1}else if(count == 1){util = $13; print gpunum " " util; count=count+1} else {count=0}}' | awk '{if ($2 == "0%"){print $1}}' | sort | wc -l`

echo "pick GPU: $gpunum"
echo "there are $gpucount GPUs available. "

if ($gpucount == "0") then
   echo "no free GPUs"
   logout
endif

nvidia-smi | grep -A1 "Tesla" | awk ' BEGIN{count=0} {if (count == 0) {gpunum = $2; count = count+1}else if(count == 1){util = $13; print gpunum " " util; count=count+1} else {count=0}}' | awk '{if ($2 == "0%"){print $1}}' | sort | head -1

setenv CUDA_VISIBLE_DEVICES  `nvidia-smi | grep -A1 "Tesla" | awk ' BEGIN{count=0} {if (count == 0) {gpunum = $2; count = count+1}else if(count == 1){util = $13; print gpunum " " util; count=count+1} else {count=0}}' | awk '{if ($2 == "0%"){print $1}}' | sort | head -1` 



