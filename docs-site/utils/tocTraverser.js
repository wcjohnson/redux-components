
export default function tocTraverser(node){
  if(node.tagName == 'li') {
    var firstChild = node.children[1]
    if(firstChild && (firstChild.tagName === 'p')) {
      var href = node.children[1].children[0].properties.href
      node.properties.section = href.replace('#', '')
      node.tagName = 'TocSection'
    }
  }

  if(node.children) {
    node.children = node.children.map(tocTraverser)
  }

  return node
}
