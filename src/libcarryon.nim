# SPDX-FileCopyrightText: 2026 b0nn133 <b0nn133@noreply.codeberg.org>
# SPDX-License-Identifier: LGPL-3.0-only

## libcarryon - entry point

import libcarryon/[types, parser, utils, archive], std/[parsecfg, streams, tables]

export types, parser, utils, archive, tables # export modules so they're available when importing the lib

const nimble = staticRead "../libcarryon.nimble" # read nimble at compile-time
const version* = nimble.newStringStream.loadConfig.getSectionValue("", "version") # get version from the nimble file