using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class MadRenderObjectsPass : ScriptableRenderPass
{
    private readonly string tag;
    private readonly MadRenderObjects.RenderQueueType renderQueueType;

    public Material overrideMaterial { get; set; }
    public int overrideMaterialPassIndex { get; set; }

    private FilteringSettings filteringSettings;
    private readonly List<ShaderTagId> shaderTagIds;
    private RenderStateBlock renderStateBlock;
    private RenderTargetHandle destination;

    
    public MadRenderObjectsPass(string tag, int layerMask, MadRenderObjects.RenderQueueType renderQueueType)
    {
        this.tag = tag;
        this.renderQueueType = renderQueueType;

        filteringSettings = new FilteringSettings(
            renderQueueType == MadRenderObjects.RenderQueueType.Transparent
                ? RenderQueueRange.transparent
                : RenderQueueRange.opaque,
            layerMask);

        shaderTagIds = new List<ShaderTagId>
        {
            new ShaderTagId("UniversalForward"),
            new ShaderTagId("LightweightForward"),
            new ShaderTagId("SRPDefaultUnlit")
        };

        renderStateBlock = new RenderStateBlock(RenderStateMask.Nothing);
    }

    public void Setup(RenderTargetHandle destination)
    {
        this.destination = destination;
    }

    public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
    {
        if (destination != RenderTargetHandle.CameraTarget)
        {
            var descriptor = cameraTextureDescriptor;
            descriptor.depthBufferBits = 24;
            descriptor.mipCount = 1;

            cmd.GetTemporaryRT(destination.id, descriptor);
            ConfigureTarget(destination.Identifier(), destination.Identifier());
            ConfigureClear(ClearFlag.All, Color.clear);
        }
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        SortingCriteria sortingCriteria = renderQueueType == MadRenderObjects.RenderQueueType.Transparent
            ? SortingCriteria.CommonTransparent
            : renderingData.cameraData.defaultOpaqueSortFlags;

        var drawingSettings = CreateDrawingSettings(shaderTagIds, ref renderingData, sortingCriteria);
        drawingSettings.overrideMaterial = overrideMaterial;
        drawingSettings.overrideMaterialPassIndex = overrideMaterialPassIndex;

        CommandBuffer cmd = CommandBufferPool.Get(tag);
        using (new ProfilingSample(cmd, tag))
        {
            context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref filteringSettings, ref renderStateBlock);
        }
        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }

    public override void FrameCleanup(CommandBuffer cmd)
    {
        if (destination == RenderTargetHandle.CameraTarget)
            cmd.ReleaseTemporaryRT(destination.id);
    }
}
