# Docker镜像批量load, tag, push

## 说明

1. 搜索目录下的所有归档文件（通过通配符指定："*.tar", "*.tar.gz", "*.tar*"）；
2. 通过`docker load -i`命令加载镜像；
3. 读取加载镜像的name和tag，使用`docker tag`生成新的镜像tag，registry和organization需要使用参数指定，name和tag会原样保留；
4. 将镜像使用`docker push`推送到镜像仓库中。

## 准备

1. 环境上须安装docker；
2. docker通过swr的登录指令登录成功；
3. 镜像拷贝到当前环境；
4. 当前环境空余磁盘空间须大于最大的docker镜像，最好有50-100G的空余空间。


## 使用

0. 将[脚本](./image_batch_loader.sh)上传到指定环境，并修改文件可执行权限
```
chmod +x image_batch_loader.sh
```

1. 查询使用帮助
```bash
./image_batch_loader.sh -h
Usage: ./image_batch_loader.sh [OPTIONS]

Load Docker tar/tar.gz files and push them to a registry.

Required Options:
  --registry URL           Registry URL (required)
  --organization NAME      Organization/namespace (required)

Optional Options:
  --delete                Delete tar files after successful processing
  --move-to DIR           Move tar files to directory after successful processing
  --directory, -d DIR     Directory containing tar files (default: current directory)
  --pattern, -p PATTERN   File pattern to match (default: *.tar*)
  --help, -h              Show this help message

Examples:
  ./image_batch_loader.sh --registry myregistry.com --organization myorg
  ./image_batch_loader.sh --registry myregistry.com --organization myorg --directory /path/to/images
  ./image_batch_loader.sh --registry myregistry.com --organization myorg --pattern "*.tar.gz"
  ./image_batch_loader.sh --registry myregistry.com --organization myorg --delete --directory /path/to/images
  ./image_batch_loader.sh --registry myregistry.com --organization myorg --move-to /processed --directory /path/to/images
  ./image_batch_loader.sh --registry myregistry.com --organization myorg -d /path/to/images -p "*.tar*" --move-to /processed

Background Execution:
  nohup ./image_batch_loader.sh --registry myregistry.com --organization myorg --directory /path/to/images > batch_loader.log 2>&1 &
  nohup ./image_batch_loader.sh --registry myregistry.com --organization myorg --delete --directory /path/to/images > /dev/null 2>&1 &
```

2. 上传当前目录下匹配 `*.tar*` 的镜像
```bash
# 默认的匹配 pattern 是 *.tar*
./image_batch_loader.sh  --registry swr.region.cloud.com --organization com-huaweicloud-lmstudio
```

```output
2025-09-17 11:12:58 [INFO] [PID:1514976] === Docker Batch Loader Started ===
2025-09-17 11:12:58 [INFO] [PID:1514976] Registry: swr.region.cloud.com
2025-09-17 11:12:58 [INFO] [PID:1514976] Organization: com-huaweicloud-lmstudio
2025-09-17 11:12:58 [INFO] [PID:1514976] Directory: .
2025-09-17 11:12:58 [INFO] [PID:1514976] Pattern: *.tar*
2025-09-17 11:12:58 [INFO] [PID:1514976] Delete after process: false
2025-09-17 11:12:58 [INFO] [PID:1514976] Checking dependencies...
2025-09-17 11:12:58 [INFO] [PID:1514976] Validating configuration...
2025-09-17 11:12:58 [INFO] [PID:1514976] Found 1 files to process
2025-09-17 11:12:58 [INFO] [PID:1514976] Processing file 1 of 1: hce2_0_torch_2_1_py3_9-25.06.27.tar.gz
2025-09-17 11:12:58 [INFO] [PID:1514976] Processing: hce2_0_torch_2_1_py3_9-25.06.27.tar.gz
2025-09-17 11:17:45 [INFO] [PID:1514976] Loading image from hce2_0_torch_2_1_py3_9-25.06.27.tar.gz...
2025-09-17 11:21:02 [INFO] [PID:1514976] Loaded image ID: registry-cbu.huawei.com/com-huaweicloud-iit-alg/hce2_0_torch_2_1_py3_9:STUDIO_DEV-20250627164035.470195508a68fe0df2947948258ae005b2975ab5
2025-09-17 11:21:02 [INFO] [PID:1514976] Tagging image as: swr.region.cloud.com/com-huaweicloud-lmstudio/hce2_0_torch_2_1_py3_9:STUDIO_DEV-20250627164035.470195508a68fe0df2947948258ae005b2975ab5
2025-09-17 11:21:02 [INFO] [PID:1514976] Successfully tagged image
2025-09-17 11:21:02 [INFO] [PID:1514976] Pushing to registry...
2025-09-17 11:21:03 [INFO] [PID:1514976] Successfully pushed swr.region.cloud.com/com-huaweicloud-lmstudio/hce2_0_torch_2_1_py3_9:STUDIO_DEV-20250627164035.470195508a68fe0df2947948258ae005b2975ab5
swr.region.cloud.com/com-huaweicloud-lmstudio/hce2_0_torch_2_1_py3_9:STUDIO_DEV-20250627164035.470195508a68fe0df2947948258ae005b2975ab5
2025-09-17 11:21:03 [INFO] [PID:1514976] ✓ Successfully processed: hce2_0_torch_2_1_py3_9-25.06.27.tar.gz
2025-09-17 11:21:03 [INFO] [PID:1514976] === SUMMARY ===
2025-09-17 11:21:03 [INFO] [PID:1514976] Successfully processed: 1 files
2025-09-17 11:21:03 [INFO] [PID:1514976] Failed: 0 files
2025-09-17 11:21:03 [INFO] [PID:1514976] Total files: 1
2025-09-17 11:21:03 [INFO] [PID:1514976] Log file: docker_batch_loader_20250917_111258_1514976.log
2025-09-17 11:21:03 [INFO] [PID:1514976] All files processed successfully
2025-09-17 11:21:03 [INFO] [PID:1514976] Cleaning up...
```

3. 上传指定目录下的 `*.tar.gz` 镜像
```bash
# 使用 --pattern "*.tar.gz" 会跳过类似 *.tar.gz.cms 等签名验证文件
./image_batch_loader.sh  --registry swr.region.cloud.com --organization com-huaweicloud-lmstudio --directory images/ --pattern "*.tar.gz"
```

4. 上传指定目录下的镜像，并将上传完成的本地镜像文件删除

```bash
./image_batch_loader.sh --registry myregistry.com --organization com-huaweicloud-lmstudio --delete --directory ./images
```

5. 上传指定目录下的镜像，并将上传完成的本地镜像文件移动到其他目录

```bash
# 这样如果有处理失败的镜像，可以再人工检查和处理后重新执行下面的命令，继续处理后续的镜像
./image_batch_loader.sh --registry myregistry.com --organization com-huaweicloud-lmstudio --directory ./images --move-to ./successfully-processed
```

6. 使用nohup后台执行

```bash
nohup ./image_batch_loader.sh --registry myregistry.com --organization myorg --delete --directory /path/to/images > /dev/null 2>&1 &
# 查看执行日志
tail -f docker_batch_loader_*.log
```

7. 更多用法参考 `usage` 说明


## FAQ

* 上传失败，报错信息 - xxx.tar.gz: Failed to load image - Invalid Docker image or corrupted tar
可能的原因：
1. 文件损坏，使用文件校验工具校验检查一下； 
2. 镜像格式不对，有些镜像会多压缩一层，需要先解压再上传：
```bash
tar -xvf xxx.tar.gz
# 解压得到的 xxx.tar 文件是合法的镜像文件
```

* 日志在哪里看？
当前目录下生成的 `docker_batch_loader_*.log` 文件
