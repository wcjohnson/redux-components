import React from 'react'
import cx from 'classnames'

import remark from 'remark'
import toc from 'remark-toc'
import slug from 'remark-slug'

import { highlight } from 'highlight.js'

import rawDocs from '!raw!./docs.md'

import markdownToReact from 'utils/mdToReact'
import tocTraverser from 'utils/tocTraverser'
import docTraverser from 'utils/docTraverser'

import { Container, Grid, Span } from 'react-responsive-grid'

function transformMarkdown() {
  var markdownWithTOC = remark()
    .use(toc)
    .process(rawDocs)
    .contents

  var split = markdownWithTOC.split('\n## ')
  var tocMD = split[0].replace('## TOC\n', '')
  var docMD = '## ' + split.slice(1).join('\n## ')

  var TOC = remark()
    .use(slug)
    .use(markdownToReact, {
      traverse: tocTraverser,
      remarkReactComponents: {
        TocSection: TocSection
      }
    })
    .process(tocMD)
    .contents

  var Docs = remark()
    .use(slug)
    .use(markdownToReact, {
      sanitize: { clobber: ["name"] },
      traverse: docTraverser,
      remarkReactComponents: {
        CodeSection: CodeSection
      }
    })
    .process(docMD)
    .contents
    .props.children

  return { TOC, Docs }
}

var tmd = transformMarkdown()
var TOCComponents = tmd.TOC, DocComponents = tmd.Docs;

function PureDocContents(props) {
  return <div>
    {DocComponents}
  </div>
}

function TocSection({ children, section }, { activeSections }) {
  var isActive = false
  if (section && activeSections.has(section)) isActive = true
  var classes = cx("nav-item", { active: isActive })

  return <li className={classes}>
    {children}
  </li>
}

function CodeSection({code}) {
  var html = highlight('jsx', code, true).value

  return <pre>
    <code dangerouslySetInnerHTML={{ __html: html }} />
  </pre>
}

TocSection.contextTypes = {
  activeSections: React.PropTypes.object.isRequired
}

export default class Docs extends React.Component {
  constructor() {
    super()
    this.state = {
      activeSections: new Set()
    }
  }

  getChildContext() {
    var activeSections = this.state.activeSections
    return { activeSections, onEnter: this.onEnter.bind(this), onLeave: this.onLeave.bind(this) }
  }

  onEnter(sectionId) {
    var activeSections = this.state.activeSections
    activeSections.add(sectionId)
    this.setState({ activeSections })
  }

  onLeave(sectionId) {
    var activeSections = this.state.activeSections
    activeSections.delete(sectionId)
    this.setState({ activeSections })
  }

  render() {
    return <Container>
      <Grid columns={12}>
        <Span columns={3}>
          {TOCComponents}
        </Span>
        <Span columns={9} last>
          <PureDocContents />
        </Span>
      </Grid>
    </Container>
  }
}

Docs.childContextTypes = {
  activeSections: React.PropTypes.object,
  onEnter: React.PropTypes.func,
  onLeave: React.PropTypes.func
}
