task :server do
  sh "nim c -r server.nim"
end

task :release do
  sh "nim c -d:release server.nim"
end

task :testgraph do
  sh "nim c -r lib/graph.nim"
end
