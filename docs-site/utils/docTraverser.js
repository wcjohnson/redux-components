export default function docTraverser(node) {
  switch(node.tagName) {
    case 'h2':
    case 'h3':
      node.children.unshift(makeHeadingAnchor(node.properties.id))
      break

    case 'pre':
      if(node.children.length === 1 && node.children[0].tagName === 'code') {
        var textNodes = node.children[0].children
        // replace, don't recurse
        return makeCodeRow(textNodes)
      }
      break

    case 'div':
      node.children = wrapIntoSectionsByH2(node.children)
      break
  }

  if(node.children)
    node.children = node.children.map(docTraverser)

  return node
}

function wrapIntoSectionsByH2(children) {
  var sections = []
  children.forEach( child => {
    if(child.tagName == 'h2') {
      var id = `section-${child.properties.id}`
      var newSection = makeSection(id, [child])
      sections.push(newSection)
    } else if (child.value !== '\n') {
      if (sections.length < 1)
        sections.push(makeSection('first', []))
      var currentSection = sections[sections.length - 1]
      currentSection.children.push(child)
    }
  })

  return sections
}

function makeSection(id, children) {
  return {
    type: 'element',
    tagName: 'section',
    properties: { id },
    children
  }
}

function makeHeadingAnchor(id) {
  return {
    type: 'element',
    tagName: 'a',
    properties: { href: `#${id}`, class: 'heading-anchor' },
    children: [{
      type: 'element',
      tagName: 'svg',
      properties: {
        ariaHidden: true,
        height: '16',
        version: '1.1',
        width: '16'
      },
      children: [{
        type: 'element',
        tagName: 'path',
        properties: {
          fill: '#666666',
          d: 'M4 9h1v1H4c-1.5 0-3-1.69-3-3.5S2.55 3 4 3h4c1.45 0 3 1.69 3 3.5 0 1.41-.91 2.72-2 3.25V8.59c.58-.45 1-1.27 1-2.09C10 5.22 8.98 4 8 4H4c-.98 0-2 1.22-2 2.5S3 9 4 9zm9-3h-1v1h1c1 0 2 1.22 2 2.5S13.98 12 13 12H9c-.98 0-2-1.22-2-2.5 0-.83.42-1.64 1-2.09V6.25c-1.09.53-2 1.84-2 3.25C6 11.31 7.55 13 9 13h4c1.45 0 3-1.69 3-3.5S14.5 6 13 6z'
        }
      }]
    }]
  }
}

function makeCodeRow(textNodes) {
  var code = textNodes.map(n => n.value).join('').trim()

  return {
    type: 'element',
    tagName: 'CodeSection',
    properties: { code },
    children: []
  }
}
