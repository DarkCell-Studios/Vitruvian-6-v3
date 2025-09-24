# Cantaloupe IIIF Proxy for NASA Lunar Kaguya GeoTIFFs

This project packages the [Cantaloupe IIIF Image Server](https://cantaloupe-project.github.io/) so it can stream
NASA's large **SELENE / Kaguya Multispectral Imager** GeoTIFF mosaics directly from the official AWS Open Data
bucket without downloading them locally first. Identifiers are resolved to S3 object URLs via a lightweight Ruby
delegate script.

## Requirements

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (or any Docker Engine with build support)
- Internet connectivity to reach the public NASA S3 bucket

> **Note for Windows users:** run the commands below from *PowerShell* or *Git Bash* after installing Docker
> Desktop. If `docker` reports "command not found" you still need to finish the Docker installation and restart
> your shell. This repository does **not** use Node.js or `npm` tooling.

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

## Run the container

```bash
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
| Build fails with `context must be a directory` | Re-run `docker build` **with** the trailing `.` while in the repository root. |
| Requests return 404 | Check the container logs; an unknown identifier will be logged by `delegates.rb`. |

## License

This repository contains configuration and helper files only and is released into the public domain.
