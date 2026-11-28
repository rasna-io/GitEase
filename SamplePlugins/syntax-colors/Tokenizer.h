#pragma once

#include <QVector>

#include "Languages.h"

namespace CodeViewer {

//! What a line leaves open for the next one: a multi-line region and the bracket depth.
struct LineState
{
    int block = -1;
    int depth = 0;
};

//! One token per character of \a text; \a state is read and updated for the next line.
QVector<Token> tokenizeLine(const Language &language, const QString &text, LineState &state, bool rainbow);

} // namespace CodeViewer
