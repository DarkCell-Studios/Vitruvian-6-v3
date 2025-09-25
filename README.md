# Cantaloupe IIIF Proxy for NASA Lunar Kaguya GeoTIFFs

This project packages the [Cantaloupe IIIF Image Server](https://cantaloupe-project.github.io/) so it can stream
NASA's large **SELENE / Kaguya Multispectral Imager** GeoTIFF mosaics directly from the official AWS Open Data
bucket without downloading them locally first. Identifiers are resolved to S3 object URLs via a lightweight Ruby
delegate script.

## Requirements

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (or any Docker Engine with build support)
- Internet connectivity so the Docker build can download the Cantaloupe distribution (Maven Central with a GitHub
  release fallback)
- Access to the public NASA S3 bucket that hosts the Kaguya mosaics

> **Note for Windows users:** run the commands below from *PowerShell* or *Git Bash* after installing Docker
> Desktop. Make sure Docker Desktop is running (look for the whale icon in the system tray) before invoking any
> `docker` commands. If `docker` reports "command not found" you still need to finish the Docker installation and
> restart your shell. This repository does **not** use Node.js or `npm` tooling.

## Clone the repository

```powershell
# PowerShell example
cd D:\Work
git clone https://github.com/<your-org>/Vitruvian-6-v3.git
cd Vitruvian-6-v3
```

## Build the image

Run from the repository root and keep the trailing `.` which tells Docker to use the current directory as the
build context.

```bash
docker build -t nasa-kaguya-iiif .
```

The Dockerfile first tries to download the official Cantaloupe `6.0.0` zip from Maven Central, then falls back to the
GitHub release asset if Maven is not reachable.

### Offline or firewalled environments

If neither Maven Central nor GitHub are accessible from your build host, download the
`cantaloupe-6.0.0.zip` archive separately (for example on a machine with internet access) and point the build to it:

```bash
docker build \
  --build-arg CANTALOUPE_PRIMARY_URL=file:///absolute/path/to/cantaloupe-6.0.0.zip \
  -t nasa-kaguya-iiif .
```

Any URL understood by `curl` works here, so you can also host the zip on an internal HTTP server and provide that URL
instead. If you do not want a fallback attempt, set `--build-arg CANTALOUPE_FALLBACK_URL=` (empty string).

## Run the container

```bash
mkdir -p cache

docker run \
  --rm \
  -p 8182:8182 \
  -v $(pwd)/cache:/var/cache/cantaloupe \
  nasa-kaguya-iiif
```

- The container listens on port **8182**.
- A local `cache/` directory is mounted into the container so tiles and info documents can be reused across runs.
- JVM heap size is fixed to `-Xmx4g` inside the image; adjust the Docker resource limits if you need more.

### Windows path syntax

If you prefer PowerShell syntax for the cache volume, replace the mount with:

```powershell
-v ${PWD}/cache:/var/cache/cantaloupe
```

## IIIF identifiers

The delegates script maps short identifiers to NASA S3 object URLs:

| Identifier      | Description                             | S3 Object |
| --------------- | --------------------------------------- | --------- |
| `kaguya-band1`  | Multispectral Imager band 1 (414 nm)    | `s3://nasa-lunar-data/kaguya/mi/global_mosaic_60m/Kaguya_MI_Band1_60m.tif` |
| `kaguya-band2`  | Multispectral Imager band 2 (749 nm)    | `s3://nasa-lunar-data/kaguya/mi/global_mosaic_60m/Kaguya_MI_Band2_60m.tif` |

To add more products, edit [`delegates.rb`](delegates.rb) and add an identifier → URL mapping.

## Example IIIF requests

Once the container is running, try the following endpoints:

- `http://localhost:8182/iiif/2/kaguya-band1/info.json`
- `http://localhost:8182/iiif/2/kaguya-band1/full/800,/0/default.jpg`
- `http://localhost:8182/iiif/2/kaguya-band1/20000,20000,1000,1000/full/0/default.png`

Replace `kaguya-band1` with `kaguya-band2` for the alternate wavelength.

## Configuration files

- [`cantaloupe.properties`](cantaloupe.properties) exposes the IIIF 2.0 endpoint, enables the delegates script,
  and configures filesystem caching so repeated requests do not re-download tiles.
- [`delegates.rb`](delegates.rb) performs identifier resolution to the remote S3 GeoTIFFs and logs when an unknown
  identifier is requested.

The Docker image copies both files into `/etc/cantaloupe/` and sets the appropriate ownership for the bundled
non-root `cantaloupe` user.

## Customization

- Adjust the JVM heap by editing the `ENTRYPOINT` line in [`Dockerfile`](Dockerfile) if your workload requires more
  or less memory.
- To use a different cache location, either change `FilesystemCache.pathname` in
  [`cantaloupe.properties`](cantaloupe.properties) or mount a different host path into `/var/cache/cantaloupe`.
- If you already host the Kaguya GeoTIFFs elsewhere, point the delegate mappings to your preferred URLs.

## Troubleshooting

| Symptom | Fix |
| ------- | --- |
| `docker: command not found` | Install Docker Desktop (or start the Docker daemon) and reopen your terminal. |
| `open //./pipe/dockerDesktopLinuxEngine: The system cannot find the file specified.` | Start Docker Desktop so the Linux container engine is running, then retry the build. |
| `curl: (56) CONNECT tunnel failed, response 403` during `docker build` | Provide a reachable `CANTALOUPE_PRIMARY_URL` or ensure the build host can access Maven Central or GitHub. |
| Build fails with `context must be a directory` | Re-run `docker build` **with** the trailing `.` while in the repository root. |
| Requests return 404 | Check the container logs; an unknown identifier will be logged by `delegates.rb`. |

## License

This repository contains configuration and helper files only and is released into the public domain.
