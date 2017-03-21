import React from 'react'
import { Link } from 'react-router'

import { Container, Grid, Span } from 'react-responsive-grid'

import post from './frontmatter.md'

export default class FrontPage extends React.Component {
  render() {
    return (
      <Container>
        <Grid columns={12}>
          <Span columns={6} className="text-center">
            <h2>Install</h2>
            <pre>$ npm install --save redux-components</pre>
          </Span>
          <Span columns={6} last className="text-center">
            <h2>Learn</h2>
            <div><Link to="docs/">Docs</Link></div>
            <div><a target="_blank" href="https://gitter.im/redux-components/Lobby">Gitter</a></div>
          </Span>
          <Span columns={12} last>
            <hr />
            <div className="markdown">
              <h1>{post.title}</h1>
              <div dangerouslySetInnerHTML={{ __html: post.body }} />
            </div>
          </Span>
        </Grid>
      </Container>
    )
  }
}
